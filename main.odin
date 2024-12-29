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




read_shader :: proc(filepath: string) -> string{
	data, ok := os.read_entire_file(filepath, context.allocator)
	if !ok {
        fmt.print("Couldnt read file")
		return ""
	}
	defer delete(data, context.allocator)

    it := string(data)
    shader_text :string= ""
	for line in strings.split_lines_iterator(&it) {
        shader_text = strings.join({shader_text,line}, "")
        shader_text = strings.join({shader_text,"\n"}, "")
    }
    return shader_text
}



VAO :: u32
VBO :: u32
EBO :: u32
PROGRAM :: u32
TEXTURE :: u32

fixed_dt: f32 = 1.0 / 60.0
accumulator: f32 = 0.0
last_time: f32 = 0.0

window: glfw.WindowHandle
system: System
camera_obj: Object
heart_object: Object
grass_object: Object
scope_object: Object
submarine_object: Object
heart_object_vao,grass_object_vao, scope_object_vao, submarine_object_vao, submarine_object_vao_2: VAO
heart_object_texture,grass_object_texture, scope_object_texture, submarine_object_texture, submarine_object_texture_2: u32
camera_speed: f32 = 1.0

collision_1_object: Object
collision_1_object_vao: VAO
collision_1_object_texture: u32

collision_2_object: Object
collision_2_object_vao: VAO
collision_2_object_texture: u32

collision_3_object: Object
collision_3_object_vao: VAO
collision_3_object_texture: u32

collision_4_object: Object
collision_4_object_vao: VAO
collision_4_object_texture: u32

collision_5_object: Object
collision_5_object_vao: VAO
collision_5_object_texture: u32

collision_6_object: Object
collision_6_object_vao: VAO
collision_6_object_texture: u32

collision_7_object: Object
collision_7_object_vao: VAO
collision_7_object_texture: u32

collision_8_object: Object
collision_8_object_vao: VAO
collision_8_object_texture: u32

mode: i32 = 0
collision_objects := make([dynamic]^Object, 0)
wireframe_enabled: bool = false

watch: time.Stopwatch

mouse_x, mouse_y: f64
last_mouse_posx, last_mouse_posy: f64

main :: proc() {
    glfw.Init()
    defer glfw.Terminate()

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    window = glfw.CreateWindow(1920, 1080, "MINI GAME ENGINE", nil, nil)
    assert(window != nil)
    defer glfw.DestroyWindow(window)
    
    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)

    gl.load_up_to(3,3, glfw.gl_set_proc_address)

    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

    tex_sun_vertex_shader   := string(#load("shaders/texture_no_l_v.glsl"  ))
    tex_sun_fragment_shader := string(#load("shaders/texture_no_l_f.glsl"))

    tex_sun_program, tex_sun_program_ok := gl.load_shaders_source(tex_sun_vertex_shader, tex_sun_fragment_shader)
    tex_sun_shader_locations :[dynamic]u32
    tex_sun_shader: Shader = {tex_sun_program, tex_sun_shader_locations}

    tex_vertex_shader   := string(#load("shaders/texture_v.glsl"))
    tex_fragment_shader := string(#load("shaders/texture_f.glsl"))

    tex_program, tex_program_ok := gl.load_shaders_source(tex_vertex_shader, tex_fragment_shader)
    tex_shader_locations :[dynamic]u32
    tex_shader: Shader = {tex_program, tex_shader_locations}

    
    if !tex_program_ok {
        fmt.println("ERROR: Failed to load and compile shaders."); os.exit(1)
    }
    
    heart_object = init_model_object(
        "./models/heart.obj",
        linalg.Vector3f32{0.0, 2.0, 0.0},
        linalg.Vector3f32{0.0, 0.0, 0.0},
        linalg.Vector3f32{1.0, 1.0, 1.0},
        &tex_shader
    ) 
    model_data := heart_object.model_data^
    heart_object_vao, heart_object_texture = setup_model_object(model_data, "./models/textures/")
    append(&model_data.material.textures, heart_object_texture)
    heart_object.model_data = &model_data

    submarine_object = init_model_object(
        "./models/submarine.obj",
        linalg.Vector3f32{0.0, 2.0, 0.0},
        linalg.Vector3f32{0.0, 0.0, 0.0},
        linalg.Vector3f32{1.0, 1.0, 1.0},
        &tex_shader
    )
    model_data_2 := submarine_object.model_data^
    submarine_object_vao, submarine_object_texture = setup_model_object(model_data_2, "./models/textures/")
    append(&model_data_2.material.textures, submarine_object_texture)
    submarine_object.model_data = &model_data_2

    scope_object = init_model_object(
        "./models/scope.obj",
        linalg.Vector3f32{0.0, -3.5, 1.0},
        linalg.Vector3f32{0.0, 0.0, 0.0},
        linalg.Vector3f32{1.0, 1.0, 1.0},
        &tex_shader
    )
    model_data_4 :=scope_object.model_data^
    scope_object_vao,scope_object_texture = setup_model_object(model_data_4, "./models/textures/")
    append(&model_data_4.material.textures,scope_object_texture)
    scope_object.model_data = &model_data_4

    grass_object = init_model_object(
        "./models/grass.obj",
        linalg.Vector3f32{0.0, 0.0, 0.0},
        linalg.Vector3f32{0.0, 0.0, 0.0},
        linalg.Vector3f32{1.0, 1.0, 1.0},
        &tex_shader
    )
    model_data_5 :=grass_object.model_data^
    grass_object_vao,grass_object_texture = setup_model_object(model_data_5, "./models/textures/")
    append(&model_data_5.material.textures,grass_object_texture)
    grass_object.model_data = &model_data_5
    move_object(&grass_object, {0.0,-8.0,0.0})

    collision_1_object = init_model_object(
        "./models/collision1.obj",
        linalg.Vector3f32{-40.0, 10.0, 0.0},
        linalg.Vector3f32{0.0, 0.0, 0.0},
        linalg.Vector3f32{1.0, 1.0, 1.0},
        &tex_shader
    )
    model_data_6 :=collision_1_object.model_data^
    collision_1_object_vao,collision_1_object_texture = setup_model_object(model_data_6, "./models/textures/")
    append(&model_data_6.material.textures,collision_1_object_texture)
    collision_1_object.model_data = &model_data_6
    move_object(&collision_1_object, {0.0,-8.0,0.0})

    collision_2_object = init_model_object(
        "./models/collision2.obj",
        linalg.Vector3f32{-30.0, 10.0, 0.0},
        linalg.Vector3f32{0.0, 0.0, 0.0},
        linalg.Vector3f32{1.0, 1.0, 1.0},
        &tex_shader
    )
    model_data_7 :=collision_2_object.model_data^
    collision_2_object_vao,collision_2_object_texture = setup_model_object(model_data_7, "./models/textures/")
    append(&model_data_7.material.textures,collision_2_object_texture)
    collision_2_object.model_data = &model_data_7
    move_object(&collision_2_object, {0.0,-8.0,0.0})

    collision_3_object = init_model_object(
        "./models/collision3.obj",
        linalg.Vector3f32{-20.0, 10.0, 0.0},
        linalg.Vector3f32{0.0, 0.0, 0.0},
        linalg.Vector3f32{1.0, 1.0, 1.0},
        &tex_shader
    )
    model_data_8 :=collision_3_object.model_data^
    collision_3_object_vao,collision_3_object_texture = setup_model_object(model_data_8, "./models/textures/")
    append(&model_data_8.material.textures,collision_3_object_texture)
    collision_3_object.model_data = &model_data_8
    move_object(&collision_3_object, {0.0,-8.0,0.0})


    collision_4_object = init_model_object(
        "./models/collision4.obj",
        linalg.Vector3f32{-10.0, 10.0, 0.0},
        linalg.Vector3f32{0.0, 0.0, 0.0},
        linalg.Vector3f32{1.0, 1.0, 1.0},
        &tex_shader
    )
    model_data_9 :=collision_4_object.model_data^
    collision_4_object_vao,collision_4_object_texture = setup_model_object(model_data_9, "./models/textures/")
    append(&model_data_9.material.textures,collision_4_object_texture)
    collision_4_object.model_data = &model_data_9
    move_object(&collision_4_object, {0.0,-8.0,0.0})

    collision_5_object = init_model_object(
        "./models/collision5.obj",
        linalg.Vector3f32{0.0, 10.0, 0.0},
        linalg.Vector3f32{0.0, 0.0, 0.0},
        linalg.Vector3f32{1.0, 1.0, 1.0},
        &tex_shader
    )
    model_data_10 :=collision_5_object.model_data^
    collision_5_object_vao,collision_5_object_texture = setup_model_object(model_data_10, "./models/textures/")
    append(&model_data_10.material.textures,collision_5_object_texture)
    collision_5_object.model_data = &model_data_10
    move_object(&collision_5_object, {0.0,-8.0,0.0})
    scale_object(&collision_5_object, {0.1,0.1,0.1})

    collision_6_object = init_model_object(
        "./models/collision6.obj",
        linalg.Vector3f32{10.0, 10.0, 0.0},
        linalg.Vector3f32{0.0, 0.0, 0.0},
        linalg.Vector3f32{1.0, 1.0, 1.0},
        &tex_shader
    )
    model_data_11 :=collision_6_object.model_data^
    collision_6_object_vao,collision_6_object_texture = setup_model_object(model_data_11, "./models/textures/")
    append(&model_data_11.material.textures,collision_6_object_texture)
    collision_6_object.model_data = &model_data_11
    move_object(&collision_6_object, {0.0,-8.0,0.0})

    collision_7_object = init_model_object(
        "./models/collision7.obj",
        linalg.Vector3f32{20.0, 10.0, 0.0},
        linalg.Vector3f32{0.0, 0.0, 0.0},
        linalg.Vector3f32{1.0, 1.0, 1.0},
        &tex_shader
    )
    model_data_12 :=collision_7_object.model_data^
    collision_7_object_vao,collision_7_object_texture = setup_model_object(model_data_12, "./models/textures/")
    append(&model_data_12.material.textures,collision_7_object_texture)
    collision_7_object.model_data = &model_data_12
    move_object(&collision_7_object, {0.0,-8.0,0.0})
    scale_object(&collision_7_object, {0.3,0.3,0.3})


    collision_8_object = init_model_object(
        "./models/collision8.obj",
        linalg.Vector3f32{30.0, 10.0, 0.0},
        linalg.Vector3f32{0.0, 0.0, 0.0},
        linalg.Vector3f32{1.0, 1.0, 1.0},
        &tex_shader
    )
    model_data_13 :=collision_8_object.model_data^
    collision_8_object_vao,collision_8_object_texture = setup_model_object(model_data_13, "./models/textures/")
    append(&model_data_13.material.textures,collision_8_object_texture)
    collision_8_object.model_data = &model_data_13
    move_object(&collision_8_object, {0.0,-8.0,0.0})



    append(&collision_objects, &collision_1_object)
    append(&collision_objects, &collision_2_object)
    append(&collision_objects, &collision_3_object)
    append(&collision_objects, &collision_4_object)
    append(&collision_objects, &collision_5_object)
    append(&collision_objects, &collision_6_object)
    append(&collision_objects, &collision_7_object)
    append(&collision_objects, &collision_8_object)

    width, height: i32
    width, height = glfw.GetFramebufferSize(window)
    ratio: = f32(system.width) / f32(system.height)

    frames := make([dynamic]Frame, 0)

    append(&frames, Frame{
        t = 0.0,
        position = linalg.Vector3f32{-4.0, 1.8, -5.0},
        rotation = linalg.Vector3f32{0.0, 0.0, 0.0},
        scale    = linalg.Vector3f32{0.4, 0.4, 0.4},
    })

    append(&frames, Frame{
        t = 1.0,
        position = linalg.Vector3f32{-4.0, 1.8, -5.0},
        rotation = linalg.Vector3f32{0.0, 0.0, 0.0},
        scale    = linalg.Vector3f32{0.6, 0.6, 0.6},
    })

    append(&frames, Frame{
        t = 2.0,
        position = linalg.Vector3f32{-4.0, 1.8, -5.0},
        rotation = linalg.Vector3f32{0.0, 0.0, 0.0},
        scale    = linalg.Vector3f32{0.4, 0.4, 0.4},
    })

    append(&frames, Frame{
        t = 3.0,
        position = linalg.Vector3f32{-4.0, 1.8,-5.0},
        rotation = linalg.Vector3f32{0.0, 0.0, 0.0},
        scale    = linalg.Vector3f32{0.6, 0.6, 0.6},
    })

    append(&frames, Frame{
        t = 4.0,
        position = linalg.Vector3f32{-4.0, 1.8, -5.0},
        rotation = linalg.Vector3f32{0.0, 0.0, 0.0},
        scale    = linalg.Vector3f32{0.4, 0.4, 0.4},
    })

    my_anim := Animation{
        animation_time = 0.0,
        frames = frames,
    }
    heart_object.animation = &my_anim


    scope_frames := make([dynamic]Frame, 0)

    append(&scope_frames, Frame{
        t = 0.0,
        position = linalg.Vector3f32{0.0, -3.5, 1.0},
        rotation = linalg.Vector3f32{0.0, 0.0, 0.0},
        scale    = linalg.Vector3f32{1.0, 1.0, 1.0},
    })

    append(&scope_frames, Frame{
        t = 1.0,
        position = linalg.Vector3f32{0.0, -3.5, 1.0},
        rotation = linalg.Vector3f32{0.0, 1.0, 0.0},
        scale    = linalg.Vector3f32{1.0, 1.0, 1.0},
    })

    append(&scope_frames, Frame{
        t = 2.0,
        position = linalg.Vector3f32{0.0, -3.5, 1.0},
        rotation = linalg.Vector3f32{0.0, 0.0, 0.0},
        scale    = linalg.Vector3f32{1.0, 1.0, 1.0},
    })

    append(&scope_frames, Frame{
        t = 3.0,
        position = linalg.Vector3f32{0.0, -3.5, 1.0},
        rotation = linalg.Vector3f32{0.0, -1.0, 0.0},
        scale    = linalg.Vector3f32{1.0, 1.0, 1.0},
    }) 
    append(&scope_frames, Frame{
        t = 4.0,
        position = linalg.Vector3f32{0.0, -3.5, 1.0},
        rotation = linalg.Vector3f32{0.0, 0.0, 0.0},
        scale    = linalg.Vector3f32{1.0, 1.0, 1.0},
    })
    scope_animation := Animation{
        animation_time = 0.0,
        frames = scope_frames,
    }
    scope_object.animation = &scope_animation

    submarine_frames := make([dynamic]Frame, 0)

    append(&submarine_frames, Frame{
        t = 0.0,
        position = linalg.Vector3f32{ 40.0,  0.0, -10.0 },
        rotation = linalg.Vector3f32{ 0.0,  0.0,  0.0 },
        scale    = linalg.Vector3f32{ 1.0,  1.0,  1.0 },
    })

    append(&submarine_frames, Frame{
        t = 1.0,
        position = linalg.Vector3f32{ 40.0,  1.0,  0.0 },
        rotation = linalg.Vector3f32{ 0.0,  0.0,  0.2 },
        scale    = linalg.Vector3f32{ 1.0,  1.0,  1.0 },
    })

    append(&submarine_frames, Frame{
        t = 2.0,
        position = linalg.Vector3f32{ 42.0, -0.5, 5.0 },
        rotation = linalg.Vector3f32{ 0.0,  0.0, -0.2 },
        scale    = linalg.Vector3f32{ 1.0,  1.0,  1.0 },
    })

    append(&submarine_frames, Frame{
        t = 3.0,
        position = linalg.Vector3f32{ 41.0,  1.5, 10.0 },
        rotation = linalg.Vector3f32{ 0.0,  0.0,  0.2 },
        scale    = linalg.Vector3f32{ 1.0,  1.0,  1.0 },
    })

    append(&submarine_frames, Frame{
        t = 4.0,
        position = linalg.Vector3f32{ 40.0, -0.5, 10.0 },
        rotation = linalg.Vector3f32{ 0.0,  1.0, -0.2 },
        scale    = linalg.Vector3f32{ 1.0,  1.0,  1.0 },
    })

    append(&submarine_frames, Frame{
        t = 5.0,
        position = linalg.Vector3f32{ 40.3, 0.3, 10.0 },
        rotation = linalg.Vector3f32{ 0.0,  3.14,  0.0 },
        scale    = linalg.Vector3f32{ 1.0,  1.0,  1.0 },
    })
    append(&submarine_frames, Frame{
        t = 6.0,
        position = linalg.Vector3f32{ 40.0,  0.0, 3.0 },
        rotation = linalg.Vector3f32{ 0.0,  3.14,  0.0 },
        scale    = linalg.Vector3f32{ 1.0,  1.0,  1.0 },
    }) 
    append(&submarine_frames, Frame{
        t = 7.0,
        position = linalg.Vector3f32{ 40.0,  0.0, -7.0 },
        rotation = linalg.Vector3f32{ 0.0,  3.14,  0.0 },
        scale    = linalg.Vector3f32{ 1.0,  1.0,  1.0 },
    }) 
    append(&submarine_frames, Frame{
        t = 8.0,
        position = linalg.Vector3f32{ 40.0,  0.0, -10.0 },
        rotation = linalg.Vector3f32{ 0.0,  2.0,  0.0 },
        scale    = linalg.Vector3f32{ 1.0,  1.0,  1.0 },
    })
    append(&submarine_frames, Frame{
        t = 9.0,
        position = linalg.Vector3f32{ 40.0,  0.0, -10.0 },
        rotation = linalg.Vector3f32{ 0.0,  0.0,  0.0 },
        scale    = linalg.Vector3f32{ 1.0,  1.0,  1.0 },
    })
    submarine_animation := Animation{
        animation_time = 0.0,
        frames = submarine_frames,
    }
    submarine_object.animation = &submarine_animation

    m,p,mvp,v :linalg.Matrix4x4f32
    camera_obj = init_camera_object(
                {2.0,0.0,3.0},
                {1.0,0.0,1.0},
                {1.0,0.0,1.0},
                )
    system = {
        &camera_obj,
        mvp,
        width,
        height,
        v,
        p,
    }

    gl.Enable(gl.DEPTH_TEST)
    move_object(&submarine_object, {0.0, 0.0, -10.0})
    add_child_to_parent(&camera_obj, &heart_object)
    add_child_to_parent(&submarine_object, &scope_object)
    scene_object := init_scene_object(
        {0.0,0.0,0.0},
        {0.0,0.0,0.0},
        {1.0,1.0,1.0})
    add_child_to_parent(&scene_object, &submarine_object)
    add_child_to_parent(&scene_object, &camera_obj)
    glfw.SetCursorPosCallback(window, mouse_callback)
    time.stopwatch_start(&watch)
    camera_speed : f32 = 1
    last_mouse_posx: f64 = mouse_x
    last_mouse_posy: f64 = mouse_y
    last_secs :f32
    glfw.SetInputMode(window,glfw.CURSOR, glfw.CURSOR_DISABLED)
    for !glfw.WindowShouldClose(window) {
        raw_duration := time.stopwatch_duration(watch)
        current_time := f32(time.duration_seconds(raw_duration))
        delta_time := current_time - last_time
        last_time = current_time

        accumulator += delta_time

        for accumulator >= fixed_dt {
            accumulator -= fixed_dt
            update_world(fixed_dt)
        }
        render_scene()
    }
}


mouse_callback :: proc "c" (window: glfw.WindowHandle, xpos, ypos: f64){
    mouse_x = xpos
    mouse_y = ypos
}
check_press := false
update_world :: proc(dt: f32) {
    movement: linalg.Vector4f32 = {0,0,0,0}
    if glfw.GetKey(window, glfw.KEY_0) == glfw.PRESS {
        mode = 0
    }
    if glfw.GetKey(window, glfw.KEY_1) == glfw.PRESS {
        mode = 1
    }
    if glfw.GetKey(window, glfw.KEY_2) == glfw.PRESS {
        mode = 2
    }
    if glfw.GetKey(window, glfw.KEY_3) == glfw.PRESS {
        mode = 3
    }
    if glfw.GetKey(window, glfw.KEY_4) == glfw.PRESS {
        mode = 4
    }
    if glfw.GetKey(window, glfw.KEY_5) == glfw.PRESS {
        mode = 5
    }
    if glfw.GetKey(window, glfw.KEY_6) == glfw.PRESS {
        mode = 6
    }
    if glfw.GetKey(window, glfw.KEY_7) == glfw.PRESS {
        mode = 7
    }
    if glfw.GetKey(window, glfw.KEY_8) == glfw.PRESS {
        mode = 8
    }
    if glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS {
        glfw.SetWindowShouldClose(window, glfw.TRUE)
    }
    if glfw.GetKey(window, glfw.KEY_F) == glfw.PRESS {
        if check_press == false{
            check_press = true
            wireframe_enabled = !wireframe_enabled
            if wireframe_enabled {
                fmt.println("Wireframe mode ON - bounding boxes will be drawn.")
            } else {
                fmt.println("Wireframe mode OFF.")
            }
        }
    } 
    if glfw.GetKey(window, glfw.KEY_F) == glfw.RELEASE {
        check_press = false
    }
    if mode == 0 {
        if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS {
            movement[2] -= camera_speed
        }
        if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS {
            movement[2] += camera_speed
        }
        if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS {
            movement[0] -= camera_speed
        }
        if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS {
            movement[0] += camera_speed
        }
    }
    else {
        idx := mode - 1
        obj := collision_objects[idx]

        speed: f32 = 0.1
        move_delta := linalg.Vector3f32{0,0,0}

        if glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS {
            move_delta.z -= speed
        }
        if glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS {
            move_delta.z += speed
        }
        if glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS {
            move_delta.x -= speed
        }
        if glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS {
            move_delta.x += speed
        }

        rot_delta_z: f32 = 0
        if glfw.GetKey(window, glfw.KEY_Q) == glfw.PRESS {
            rot_delta_z += 0.01
        }
        if glfw.GetKey(window, glfw.KEY_E) == glfw.PRESS {
            rot_delta_z -= 0.01
        }

        new_scale := obj.scale
        scale_speed: f32 = 0.01

        if glfw.GetKey(window, glfw.KEY_MINUS) == glfw.PRESS {
            new_scale.x -= scale_speed
            new_scale.y -= scale_speed
            new_scale.z -= scale_speed
        }
        if glfw.GetKey(window, glfw.KEY_EQUAL) == glfw.PRESS {
            new_scale.x += scale_speed
            new_scale.y += scale_speed
            new_scale.z += scale_speed
        }
        if new_scale.x < 0.1 { new_scale.x = 0.1 }
        if new_scale.y < 0.1 { new_scale.y = 0.1 }
        if new_scale.z < 0.1 { new_scale.z = 0.1 }

        if move_delta != linalg.Vector3f32({0,0,0}) {
            move_object(obj, move_delta)
        }
        if rot_delta_z != 0 {
            rotate_object(obj, linalg.Vector3f32{0,0,rot_delta_z})
        }
        scale_object(obj, new_scale)
    }

    system.camera.yaw   += (f32(mouse_x) - f32(last_mouse_posx)) * 0.01
    system.camera.pitch += (f32(mouse_y) - f32(last_mouse_posy)) * 0.01
    last_mouse_posx = mouse_x
    last_mouse_posy = mouse_y

    system.camera.pitch = clamp(system.camera.pitch, -0.5*math.PI, 0.5*math.PI)

    move_rotation: = linalg.identity_matrix(linalg.Matrix4x4f32)
    move_rotation = linalg.matrix4_rotate_f32(-system.camera.pitch, linalg.Vector3f32{1,0,0}) * move_rotation
    move_rotation = linalg.matrix4_rotate_f32(-system.camera.yaw,   linalg.Vector3f32{0,1,0}) * move_rotation

    rotated_movement: linalg.Vector4f32 = move_rotation * movement
    system.camera.position += linalg.Vector3f32{
        rotated_movement[0],
        rotated_movement[1],
        rotated_movement[2]
    }

    system.camera.m = make_local_matrix(
        system.camera.position,
        linalg.Vector3f32{-system.camera.pitch, -system.camera.yaw, 0},
        linalg.Vector3f32{1,1,1}
    )
    update_world_matrix(system.camera)
    play_animation(&heart_object, dt)
    play_animation(&scope_object, dt)
    play_animation(&submarine_object, dt)
    update_world_matrix(&submarine_object)
    update_world_matrix(&scope_object)
    update_world_matrix(&grass_object)
    update_world_matrix(&collision_1_object)
    update_world_matrix(&collision_2_object)
    update_world_matrix(&collision_3_object)
    update_world_matrix(&collision_4_object)
    update_world_matrix(&collision_5_object)
    update_world_matrix(&collision_6_object)
    update_world_matrix(&collision_7_object)
    update_world_matrix(&collision_8_object)

    calc_aabb(&heart_object)
    calc_aabb(&submarine_object)
    calc_aabb(&scope_object)
    calc_aabb(&grass_object)
    calc_aabb(&collision_1_object)
    calc_aabb(&collision_2_object)
    calc_aabb(&collision_3_object)
    calc_aabb(&collision_4_object)
    calc_aabb(&collision_5_object)
    calc_aabb(&collision_6_object)
    calc_aabb(&collision_7_object)
    calc_aabb(&collision_8_object)

    if check_aabb_overlap(&collision_1_object, &collision_2_object) {
        scale_object(&collision_1_object, {0.1,0.1,0.1})
    }
}

render_scene :: proc() {
    gl.Viewport(0, 0, system.width, system.height)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

    system.v = linalg.matrix4_inverse_f32(system.camera.w)
    ratio: = f32(system.width) / f32(system.height)
    system.p = linalg.matrix4_perspective_f32(system.camera.fov, ratio, 0.1, 400.0)

    if wireframe_enabled{
        gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE)
    }
    else{
        gl.PolygonMode(gl.FRONT_AND_BACK, gl.FILL)
    }
    draw_model_object(&heart_object, &system, heart_object_vao, 0, camera_obj.position)
    draw_model_object(&scope_object, &system, scope_object_vao, 0, camera_obj.position)
    draw_model_object(&submarine_object, &system, submarine_object_vao, 0, camera_obj.position)
    draw_model_object(&grass_object, &system, grass_object_vao, 0, camera_obj.position)
    draw_model_object(&collision_1_object, &system, collision_1_object_vao, 0, camera_obj.position)
    draw_model_object(&collision_2_object, &system, collision_2_object_vao, 0, camera_obj.position)
    draw_model_object(&collision_3_object, &system, collision_3_object_vao, 0, camera_obj.position)
    draw_model_object(&collision_4_object, &system, collision_4_object_vao, 0, camera_obj.position)
    draw_model_object(&collision_5_object, &system, collision_5_object_vao, 0, camera_obj.position)
    draw_model_object(&collision_6_object, &system, collision_6_object_vao, 0, camera_obj.position)
    draw_model_object(&collision_7_object, &system, collision_7_object_vao, 0, camera_obj.position)
    draw_model_object(&collision_8_object, &system, collision_8_object_vao, 0, camera_obj.position)

    glfw.SwapBuffers(window)
    glfw.PollEvents()
}
