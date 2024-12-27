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

ModelData :: struct {
    vertices : [dynamic]Vertex,
    vertices_indices : [dynamic]u32,
    material: Material,
}

Object :: struct{
    //Models
    model_data: ^ModelData,
    //Camera
    yaw, pitch, fov: f32,
    //Universal
    m : linalg.Matrix4f32,
    w : linalg.Matrix4f32,
    position: linalg.Vector3f32,
    rotation: linalg.Vector3f32,
    scale: linalg.Vector3f32,
    shader: ^Shader,
    parent: ^Object,
    children: [dynamic]^Object
}

init_model_object :: proc(
    model_path: string,
    position, rotation, 
    scale : linalg.Vector3f32, 
    shader: ^Shader,
    ) -> Object{
    children: [dynamic]^Object
    model_data := read_obj_only(model_path)
    m: linalg.Matrix4f32 = linalg.identity_matrix(linalg.Matrix4x4f32)
    w := m
    return Object {
        &model_data,
        0.0,
        0.0,
        0.0,
        m,
        w,
        position,
        rotation,
        scale,
        shader,
        nil,
        children
    }
}

init_camera_object :: proc(
    position, rotation, scale : linalg.Vector3f32, 
    shader: ^Shader,
    ) -> Object{
    children: [dynamic]^Object
    m: linalg.Matrix4f32 = linalg.identity_matrix(linalg.Matrix4x4f32)
    w := m
    return Object {
        nil,
        0.0,
        0.0,
        45.0,
        m,
        w,
        position,
        rotation,
        scale,
        shader,
        nil,
        children
    }
}

add_child_to_parent :: proc(parent: ^Object, child: ^Object){
    child.parent = parent
    //usunac
    if parent.parent == nil{
        child.w = child.parent.w * child.m
    }
    else{
        child.w = parent.m * child.m
    }
    append(&parent.children, child)
}

move_object :: proc(object: ^Object, target_position: linalg.Vector3f32){
    object.m = linalg.matrix4_translate_f32(target_position) * object.m * object.parent.w
    object.w = object.parent.w * object.m
    for child in object.children{
        move_object(child, target_position)
    }
}

rotate_object :: proc(object: ^Object, target_rotation: linalg.Vector3f32){
    object.m = linalg.matrix4_from_euler_angles_zyx_f32(target_rotation[0], target_rotation[1], target_rotation[2]) * object.m
    object.w = object.parent.w * object.m
    for child in object.children{
        move_object(child, target_rotation)
    }
}

scale_object :: proc(object: ^Object, target_scale: linalg.Vector3f32){
    object.m = linalg.matrix4_scale_f32(target_scale) * object.m * object.parent.w
    object.w = object.parent.w * object.m
    for child in object.children{
        move_object(child, target_scale)
    }
}

get_world_matrix :: proc (object: ^Object) -> linalg.Matrix4f32{
    if object.parent == nil{
        return object.m
    }
    return (object.parent.w * get_world_matrix(object.parent))
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
