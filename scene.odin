package engine

import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:time"
import "core:image"
import "core:math"
import "core:fmt"
import "core:os"
import "base:runtime"
import "core:math/linalg"
import "core:strings"
import "core:strconv"
import "core:mem"
import png "core:image/png"

Scene :: struct {
    name: string,
    root: Object,
}

Animation :: struct {
    animation_time: f32,
    frames: [dynamic]Frame
}

Camera :: struct{
    position : linalg.Vector3f32,
    yaw,pitch,fov : f32,
    v, p: linalg.Matrix4f32
}

System :: struct {
    camera: ^Object,
    mvp: linalg.Matrix4f32,
    width, height: i32,
    v, p: linalg.Matrix4f32
}

Object :: struct {
    model_data: ^ModelData,
    
    yaw, pitch, fov: f32,

    position: linalg.Vector3f32,
    rotation: linalg.Vector3f32,
    scale:    linalg.Vector3f32,

    m: linalg.Matrix4f32,
    w: linalg.Matrix4f32,

    shader: ^Shader,
    
    animation: ^Animation,

    parent: ^Object,
    children: [dynamic]^Object,
}

make_local_matrix :: proc(
    position, rotation, scale: linalg.Vector3f32
) -> linalg.Matrix4f32 {
    scale_mat := linalg.matrix4_scale_f32(scale)
    rot_mat   := linalg.matrix4_from_euler_angles_zyx_f32(
        rotation.z, 
        rotation.y, 
        rotation.x
    )
    trans_mat := linalg.matrix4_translate_f32(position)
    return trans_mat * rot_mat * scale_mat
}


init_model_object :: proc(
    model_path: string,
    position, rotation, scale: linalg.Vector3f32,
    shader: ^Shader
) -> Object {
    model_data := read_obj_only(model_path)

    local_m := make_local_matrix(position, rotation, scale)
    return Object {
        &model_data,
        0.0,
        0.0,
        0.0,
        position,
        rotation,
        scale,
        local_m,
        local_m,
        shader,
        nil,
        nil,
        make([dynamic]^Object, 0)
    }
}

init_scene_object :: proc(
    position, rotation, scale: linalg.Vector3f32,
) -> Object {
    local_m := make_local_matrix(position, rotation, scale)
    return Object {
        nil,
        0.0,
        0.0,
        0.0,
        position,
        rotation,
        scale,
        local_m,
        local_m,
        nil,
        nil,
        nil,
        make([dynamic]^Object, 0)
    }
}

init_camera_object :: proc(
    position, rotation, scale: linalg.Vector3f32,
) -> Object {
    local_m := make_local_matrix(position, rotation, scale)
    return Object {
        nil,
        0.0,
        0.0,
        45.0,
        position,
        rotation,
        scale,
        local_m,
        local_m,
        nil,
        nil,
        nil,
        make([dynamic]^Object, 0)
    }
}
add_child_to_parent :: proc(parent: ^Object, child: ^Object) {
    child.parent = parent
    append(&parent.children, child)
}

update_world_matrix :: proc(obj: ^Object) {
    if obj.parent == nil {
        obj.w = obj.m
    } else {
        obj.w = obj.parent.w * obj.m
    }

    for child in obj.children {
        update_world_matrix(child)
    }
}

move_object :: proc(obj: ^Object, delta_position: linalg.Vector3f32) {
    obj.position = obj.position + delta_position
    obj.m = make_local_matrix(obj.position, obj.rotation, obj.scale)
}

rotate_object :: proc(obj: ^Object, delta_rotation: linalg.Vector3f32) {
    obj.rotation = obj.rotation + delta_rotation
    obj.m = make_local_matrix(obj.position, obj.rotation, obj.scale)
}

scale_object :: proc(obj: ^Object, new_scale: linalg.Vector3f32) {
    obj.scale = new_scale
    obj.m = make_local_matrix(obj.position, obj.rotation, obj.scale)
}

get_world_matrix :: proc(obj: ^Object) -> linalg.Matrix4f32 {
    if obj.parent == nil {
        return obj.m
    }
    return get_world_matrix(obj.parent) * obj.m
}


/*
katy eulera aplikowac z->y->x
katalog include ISceneNode.h w irrlicht engine
wazne atrybuty - 
      - wezel rodzica, 
      - lista wskaznikow na dzieci,
      - macierz swiatowa
      - position
      - rotation (euler angle)
      - scale

przed renderingiem aktualizacja wszystkich
macierzy swiatowych
*/

Frame :: struct{
    position, rotation, scale: linalg.Vector3f32,
    t: f32,
}

lerp_vector3 :: proc(a, b: linalg.Vector3f32, t: f32) -> linalg.Vector3f32 {
    return linalg.Vector3f32{
        linalg.lerp(a.x, b.x, t),
        linalg.lerp(a.y, b.y, t),
        linalg.lerp(a.z, b.z, t),
    }
}

find_keyframe_transform :: proc(frames: [dynamic]Frame, current_time: f32) -> (x,y,z: linalg.Vector3f32)
{
    if current_time <= frames[0].t {
        return frames[0].position, 
            frames[0].rotation, 
            frames[0].scale
        
    }
    last_idx := len(frames) - 1
    if current_time >= frames[last_idx].t {
        return frames[last_idx].position, 
            frames[last_idx].rotation, 
            frames[last_idx].scale
        
    }

    prev_i: int = 0
    next_i: int = 1

    for i in 1..<last_idx+1 {
        if current_time < frames[i].t {
            prev_i = i-1
            next_i = i
            break
        }
    }

    t0 := frames[prev_i].t
    t1 := frames[next_i].t
    alpha: f32 = (current_time - t0) / (t1 - t0)

    pos := lerp_vector3(frames[prev_i].position, frames[next_i].position, alpha)
    rot := lerp_vector3(frames[prev_i].rotation, frames[next_i].rotation, alpha)
    scl := lerp_vector3(frames[prev_i].scale,    frames[next_i].scale,    alpha)

    return pos, rot, scl
}

play_animation :: proc(object: ^Object, dt: f32){
    if object.animation != nil {
        anim_end := object.animation.frames[len(object.animation.frames)-1].t
        object.animation.animation_time += dt
        if object.animation.animation_time > anim_end {
            object.animation.animation_time -= anim_end
        }
        pos, rot, scl := find_keyframe_transform(
            object.animation.frames, 
            object.animation.animation_time
        )
        object.position = pos
        object.rotation = rot
        object.scale    = scl

        object.m = make_local_matrix(pos, rot, scl)
        update_world_matrix(object)
    }
    else {
        fmt.print("Animation doesn't exist on this object")
    }
}

calc_aabb :: proc(object: ^Object) {
    cb: = object.model_data.collision_box

    minL: = cb.min_local
    maxL: = cb.max_local

    corners := [8]linalg.Vector3f32{
        {minL.x, minL.y, minL.z},
        {maxL.x, minL.y, minL.z},
        {minL.x, maxL.y, minL.z},
        {maxL.x, maxL.y, minL.z},
        {minL.x, minL.y, maxL.z},
        {maxL.x, minL.y, maxL.z},
        {minL.x, maxL.y, maxL.z},
        {maxL.x, maxL.y, maxL.z},
    }

    minX, minY, minZ := f32(999999.0),  f32(999999.0),  f32(999999.0)
    maxX, maxY, maxZ := f32(-999999.0), f32(-999999.0), f32(-999999.0)

    for i in 0..<8 {
        corner_world_4 := object.w * linalg.Vector4f32{ corners[i].x, corners[i].y, corners[i].z, 1.0 }
        cwX := corner_world_4.x
        cwY := corner_world_4.y
        cwZ := corner_world_4.z

        if cwX < minX { minX = cwX }
        if cwY < minY { minY = cwY }
        if cwZ < minZ { minZ = cwZ }
        if cwX > maxX { maxX = cwX }
        if cwY > maxY { maxY = cwY }
        if cwZ > maxZ { maxZ = cwZ }
    }

    cb.aabb_min = { minX, minY, minZ }
    cb.aabb_max = { maxX, maxY, maxZ }
    object.model_data.collision_box = cb
}

check_aabb_overlap :: proc(a: ^Object, b: ^Object) -> bool {
    cbA := a.model_data.collision_box
    cbB := b.model_data.collision_box

    minA := cbA.aabb_min
    maxA := cbA.aabb_max
    minB := cbB.aabb_min
    maxB := cbB.aabb_max

    if maxA.x < minB.x || minA.x > maxB.x { return false }
    if maxA.y < minB.y || minA.y > maxB.y { return false }
    if maxA.z < minB.z || minA.z > maxB.z { return false }

    return true
}

move_object_with_collision :: proc(obj: ^Object, delta_position: linalg.Vector3f32) {
    old_pos := obj.position
    old_rot := obj.rotation
    old_scale := obj.scale

    obj.position = obj.position + delta_position
    obj.m = make_local_matrix(obj.position, obj.rotation, obj.scale)
    update_world_matrix(obj)

    calc_aabb(obj)

    obj.position = old_pos
    obj.rotation = old_rot
    obj.scale    = old_scale
    obj.m = make_local_matrix(obj.position, obj.rotation, obj.scale)
    update_world_matrix(obj)
    calc_aabb(obj)
}

append_line :: proc(vertices: ^[dynamic]linalg.Vector3f32, 
                    p1, p2: linalg.Vector3f32) {
    append(vertices, p1)
    append(vertices, p2)
}
