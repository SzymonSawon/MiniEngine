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

watch            : time.Stopwatch

main :: proc() {
    glfw.Init()
    defer glfw.Terminate()

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    window := glfw.CreateWindow(1920, 1080, "MINI GAME ENGINE", nil, nil)
    assert(window != nil)
    defer glfw.DestroyWindow(window)
    
    glfw.MakeContextCurrent(window)
    glfw.SwapInterval(1)

    gl.load_up_to(3,3, glfw.gl_set_proc_address)


    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

    //SETUP MODELS
    //model:Model = read_obj("./models/fish_2.obj")
    //vao, fish_texture := setup_model(model,"./models/textures/")
    //append(&model.material.textures, fish_texture)

    sun_model:Model = read_obj("./models/sun.obj")
    sun_vao, sun_texture := setup_model(sun_model,"./models/textures/")
    append(&sun_model.material.textures, sun_texture)

    neptune_model:Model = read_obj("./models/neptune.obj")
    neptune_vao, neptune_texture := setup_model(neptune_model,"./models/textures/")
    append(&neptune_model.material.textures, neptune_texture)
    append(&sun_model.children, &neptune_model)

    ship_model:Model = read_obj("./models/space_ship.obj")
    ship_vao, ship_texture := setup_model(ship_model,"./models/textures/")
    append(&ship_model.material.textures, ship_texture)

    carpet_model:Model = read_obj("./models/carpet_planet.obj")
    carpet_vao, carpet_texture := setup_model(carpet_model,"./models/textures/")
    append(&carpet_model.material.textures, carpet_texture)
    append(&sun_model.children, &carpet_model)

    //SETUP SYSTEM
    m,p,mvp,v :linalg.Matrix4x4f32
    camera: Camera = {{2.0,0.0,3.0}, 0.0, 0.0, 45.0,v,p}
    width, height: i32
    width, height = glfw.GetFramebufferSize(window)
    system:System = {
        camera,
        mvp,
        width,
        height
    }

    gl.Enable(gl.DEPTH_TEST)

    tex_program_ok      : bool
    tex_vertex_shader   := string(#load("shaders/texture_v.glsl"  ))
    tex_fragment_shader := string(#load("shaders/texture_f.glsl"))

    tex_nl_program_ok      : bool
    tex_nl_vertex_shader   := string(#load("shaders/texture_no_l_v.glsl"  ))
    tex_nl_fragment_shader := string(#load("shaders/texture_no_l_f.glsl"))

    //model.shader.program, tex_program_ok = gl.load_shaders_source(tex_vertex_shader, tex_fragment_shader)
    neptune_model.shader.program, tex_program_ok = gl.load_shaders_source(tex_vertex_shader, tex_fragment_shader)
    ship_model.shader.program = neptune_model.shader.program
    carpet_model.shader.program = neptune_model.shader.program
    sun_model.shader.program, tex_nl_program_ok = gl.load_shaders_source(tex_nl_vertex_shader, tex_nl_fragment_shader)

    if !tex_program_ok {
        fmt.println("ERROR: Failed to load and compile shaders."); os.exit(1)
    }
    if !tex_nl_program_ok {
        fmt.println("ERROR: Failed to load and compile shaders."); os.exit(1)
    }

    
    particles:=init_particles(100, &sun_model)

    glfw.SetCursorPosCallback(window, mouse_callback)
    time.stopwatch_start(&watch)
    camera_speed : f32 = 0.1
    last_mouse_posx: f64 = mouse_x
    last_mouse_posy: f64 = mouse_y
    glfw.SetInputMode(window,glfw.CURSOR, glfw.CURSOR_DISABLED)
    for !glfw.WindowShouldClose(window) {

        raw_duration := time.stopwatch_duration(watch)
        secs := f32(time.duration_seconds(raw_duration))
        theta := -secs

        update_particles(particles, theta, &sun_model)

        ratio:f32 = f32(width) / f32(height)
        gl.Viewport(0,0,width,height)
        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

        movement:linalg.Vector4f32 = {0.0,0.0,0.0,0.0}
        if (glfw.GetKey(window, glfw.KEY_W) == glfw.PRESS){
            movement[2] -= camera_speed
        }
        if (glfw.GetKey(window, glfw.KEY_S) == glfw.PRESS){
            movement[2] += camera_speed
        }
        if (glfw.GetKey(window, glfw.KEY_A) == glfw.PRESS){
            movement[0] -= camera_speed
        }
        if (glfw.GetKey(window, glfw.KEY_D) == glfw.PRESS){
            movement[0] += camera_speed
        }
        if (glfw.GetKey(window, glfw.KEY_ESCAPE) == glfw.PRESS){
            glfw.SetWindowShouldClose(window, glfw.TRUE)
        }
        system.camera.yaw+=(f32(mouse_x) - f32(last_mouse_posx))*0.01
        system.camera.pitch+=(f32(mouse_y) - f32(last_mouse_posy))*0.01
        last_mouse_posx = mouse_x
        last_mouse_posy = mouse_y
        move_rotation:linalg.Matrix4x4f32
        move_rotation = linalg.identity_matrix(linalg.Matrix4x4f32)
        move_rotation = linalg.matrix4_rotate_f32(-system.camera.pitch, {1.0,0.0,0.0}) * move_rotation
        move_rotation = linalg.matrix4_rotate_f32(-system.camera.yaw, {0.0,1.0,0.0}) * move_rotation
        move_rotation = linalg.matrix4_translate_f32(
            {
                -system.camera.position[0],
                -system.camera.position[1],
                -system.camera.position[2]
            }) * move_rotation
        rotated_movement: linalg.Vector4f32 = move_rotation * movement

        system.camera.position = system.camera.position + linalg.Vector3f32{rotated_movement[0], rotated_movement[1], rotated_movement[2]}
        system.camera.pitch = clamp(system.camera.pitch, -0.5 * math.PI, 0.5 * math.PI)


        system.camera.v = linalg.identity_matrix(linalg.Matrix4x4f32)
        system.camera.v = linalg.matrix4_translate_f32(-system.camera.position) * system.camera.v
        system.camera.v = linalg.matrix4_rotate_f32(system.camera.yaw, {0.0,1.0,0.0}) * system.camera.v
        system.camera.v = linalg.matrix4_rotate_f32(system.camera.pitch, {1.0,0.0,0.0}) * system.camera.v

        system.camera.p = linalg.matrix4_perspective_f32(camera.fov, ratio, 0.1, 400.0)
        
        //draw_model(&model,&system,vao,0, {0.0,0.0,0.0}, sun_model.position)
        draw_model(&sun_model,&system,sun_vao,0, sun_model.position)
        animate_planet(&neptune_model,&system,neptune_vao,0, sun_model.position, 30.0, theta,0.5)
        animate_planet(&carpet_model,&system,carpet_vao,0, sun_model.position, 20.0, theta,0.1)


        glfw.SwapBuffers(window)
        glfw.PollEvents()
    }
}


mouse_x,mouse_y :f64
mouse_callback :: proc "c" (window: glfw.WindowHandle, xpos, ypos: f64){
    mouse_x = xpos
    mouse_y = ypos
}


