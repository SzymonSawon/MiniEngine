package engine
import "core:math/linalg"
import "core:strings"
import "core:strconv"
import "core:fmt"
import "core:os"
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:time"
import "core:math"

//make model and object structs from model struct
// to differentiate models and their objects(
//  you can draw one model as different objects at different positions)

Model :: struct{
    vertex : [dynamic]Vertex,
    vertex_indices: [dynamic]u32,
    material: Material,
    shader: Shader,
    m: linalg.Matrix4f32,
    position: linalg.Vector3f32,
    children: [dynamic]^Model
}

Material :: struct{
    ambient: linalg.Vector3f32,
    diffuse: linalg.Vector3f32,
    specular: linalg.Vector3f32,
    specular_exponent: f32,
    texture_filename: string,
    textures: [dynamic]TEXTURE
}

read_obj :: proc(filepath: string) -> Model {
    data, ok := os.read_entire_file(filepath, context.allocator)
    defer delete(data, context.allocator)


    vertices : [dynamic]linalg.Vector3f32
    normals : [dynamic]linalg.Vector3f32
    textures : [dynamic]linalg.Vector2f32
    vertex_indices : [dynamic]i64
    normal_indices : [dynamic]i64
    texture_indices : [dynamic]i64

    model_vertices: [dynamic]Vertex
    model_indices: [dynamic]u32
    material: Material
    model_ambient: linalg.Vector3f32 = linalg.Vector3f32({0.5,0.5,0.5})
    model_diffuse: linalg.Vector3f32 = linalg.Vector3f32({0.8,0.8,0.8})
    model_specular: linalg.Vector3f32 = linalg.Vector3f32({0.5,0.5,0.5})
    model_spec_exp: f32 = 1.5
    texture_filename: string
    temp_vertex: Vertex
    material_textures: [dynamic]TEXTURE
    locations: [dynamic]u32
    children_models: [dynamic]^Model
    shader: Shader = {
        0,
        locations
    }
    m: linalg.Matrix4f32

    

    it := string(data)
    counter: u32 = 0
    for line in strings.split_lines_iterator(&it) {
        str_array := strings.split(line, " ")
        if (line == "" || line[0] == '#') {
            continue
        }
        switch str_array[0] {
            case "v":
                if (len(str_array) < 4) {
                    continue
                }
                a,_ := strconv.parse_f32(str_array[1])
                b,_ := strconv.parse_f32(str_array[2])
                c,_ := strconv.parse_f32(str_array[3])
                append(&vertices, linalg.Vector3f32{
                    a,
                    b,
                    c
                })
            case "vn":
                if (len(str_array) < 4) {
                    continue
                }
                a,_ := strconv.parse_f32(str_array[1])
                b,_ := strconv.parse_f32(str_array[2])
                c,_ := strconv.parse_f32(str_array[3])
                append(&normals, linalg.Vector3f32{
                    a,
                    b,
                    c
                })
            case "vt":
                if (len(str_array) < 3) {
                    continue
                }
                a,_ := strconv.parse_f32(str_array[1])
                b,_ := strconv.parse_f32(str_array[2])
                append(&textures, linalg.Vector2f32{
                    a,
                    b
                })
            case "f":
                for i := 1; i <= 3; i+=1{
                    if (len(str_array) < 4) {
                        continue
                    }
                    a,_ := strconv.parse_i64(strings.split(str_array[i],"/")[0])
                    b,_ := strconv.parse_i64(strings.split(str_array[i],"/")[1])
                    c,_ := strconv.parse_i64(strings.split(str_array[i],"/")[2])
                    vertex: Vertex = {
                        vertices[a - 1],
                        textures[b - 1],
                        normals[c - 1]
                    }
                    id:int = find_element(model_vertices,vertex)
                    if (id == -1){
                        append(&model_vertices,vertex)
                        append(&model_indices, u32(counter))
                        counter+=1
                    }
                    else{
                        append(&model_indices, u32(id))
                    }
            }
            case "mtllib":
                mtl_filename: string = str_array[1]
                mtl_filepath:string = "./models/"
                mtl_data, ok := os.read_entire_file(strings.concatenate({mtl_filepath,mtl_filename}), context.allocator)
                it := string(mtl_data)
                for l in strings.split_lines_iterator(&it) {
                    mtl_str_array := strings.split(l, " ")
                    switch mtl_str_array[0]{
                        case "Ka":
                            a,_ := strconv.parse_f32(mtl_str_array[1])
                            b,_ := strconv.parse_f32(mtl_str_array[2])
                            c,_ := strconv.parse_f32(mtl_str_array[3])
                            model_ambient = linalg.Vector3f32{
                                a,
                                b,
                                c
                            }
                        case "Kd":
                            a,_ := strconv.parse_f32(mtl_str_array[1])
                            b,_ := strconv.parse_f32(mtl_str_array[2])
                            c,_ := strconv.parse_f32(mtl_str_array[3])
                            model_diffuse = linalg.Vector3f32{
                                a,
                                b,
                                c
                            }
                        case "Ks":
                            a,_ := strconv.parse_f32(mtl_str_array[1])
                            b,_ := strconv.parse_f32(mtl_str_array[2])
                            c,_ := strconv.parse_f32(mtl_str_array[3])
                            model_specular = linalg.Vector3f32{
                                a,
                                b,
                                c
                            }
                        case "Ns":
                            a,_ := strconv.parse_f32(mtl_str_array[1])
                            model_spec_exp = a
                        case "map_Kd":
                            texture_filename= mtl_str_array[1]
                    }
                }

                


        }
    }
    return Model {
        model_vertices, 
        model_indices, 
        Material{
            model_ambient,
            model_diffuse, 
            model_specular,
            model_spec_exp,
            texture_filename,
            material_textures
        },
        shader,
        m,
        linalg.Vector3f32({0.0,0.0,0.0}),
        children_models
    }
}


draw_model :: proc(model: ^Model, system: ^System, vao: VAO, tex_id: u32, light_source_pos: linalg.Vector3f32) {
    gl.UseProgram(model.shader.program)
    model.m = linalg.identity_matrix(linalg.Matrix4x4f32)
    model.m= linalg.matrix4_translate_f32(linalg.Vector3f32({model.position[0],model.position[1],model.position[2]})) * model.m
    system.mvp = system.camera.p * system.camera.v
    system.mvp = system.mvp * model.m

    gl.UniformMatrix4fv(gl.GetUniformLocation(model.shader.program, "MVP"   ), 1, gl.FALSE, &system.mvp[0][0])
    gl.UniformMatrix4fv(gl.GetUniformLocation(model.shader.program, "model"   ), 1, gl.FALSE, &model.m[0][0])
    gl.UniformMatrix4fv(gl.GetUniformLocation(model.shader.program, "view"), 1, gl.FALSE, &system.camera.v[0][0])
    gl.UniformMatrix4fv(gl.GetUniformLocation(model.shader.program, "projection"), 1, gl.FALSE, &system.camera.p[0][0])
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "lightColor"), 1.0,1.0,1.0)
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "objectColor"), 0.5,0.7,0.9)
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "lightPos"), light_source_pos[0], light_source_pos[1], light_source_pos[2])
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "viewPos"), system.camera.position[0], system.camera.position[1], system.camera.position[2])
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "mtlAmbient"), model.material.ambient[0], model.material.ambient[1], model.material.ambient[2])
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "mtlDiffuse"), model.material.diffuse[0], model.material.diffuse[1], model.material.diffuse[2])
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "mtlSpecular"), model.material.specular[0], model.material.specular[1], model.material.specular[2])
    gl.Uniform1f(gl.GetUniformLocation(model.shader.program, "mtlSpecularExponent"), model.material.specular_exponent)
    gl.ActiveTexture(gl.TEXTURE0 + tex_id)
    gl.BindTexture(gl.TEXTURE_2D, model.material.textures[0])
    

    gl.BindVertexArray(vao)
    gl.DrawElements(gl.TRIANGLES, i32(len(model.vertex_indices)), gl.UNSIGNED_INT, rawptr(uintptr(0)))
}

animate_sun :: proc(model: ^Model, system: ^System, vao: VAO, tex_id: u32, light_source_pos: linalg.Vector3f32,theta:f32) {
    gl.UseProgram(model.shader.program)
    model.m = linalg.identity_matrix(linalg.Matrix4x4f32)
    model.m= linalg.matrix4_translate_f32(linalg.Vector3f32({model.position[0],model.position[1],model.position[2]})) * model.m
    system.mvp = system.camera.p * system.camera.v
    system.mvp = system.mvp * model.m

    gl.UniformMatrix4fv(gl.GetUniformLocation(model.shader.program, "MVP"   ), 1, gl.FALSE, &system.mvp[0][0])
    gl.UniformMatrix4fv(gl.GetUniformLocation(model.shader.program, "model"   ), 1, gl.FALSE, &model.m[0][0])
    gl.UniformMatrix4fv(gl.GetUniformLocation(model.shader.program, "view"), 1, gl.FALSE, &system.camera.v[0][0])
    gl.UniformMatrix4fv(gl.GetUniformLocation(model.shader.program, "projection"), 1, gl.FALSE, &system.camera.p[0][0])
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "lightColor"), 1.0,1.0,1.0)
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "objectColor"), 0.5,0.7,0.9)
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "lightPos"), light_source_pos[0], light_source_pos[1], light_source_pos[2])
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "viewPos"), system.camera.position[0], system.camera.position[1], system.camera.position[2])
    gl.Uniform1f(gl.GetUniformLocation(model.shader.program, "time"), theta)
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "mtlAmbient"), model.material.ambient[0], model.material.ambient[1], model.material.ambient[2])
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "mtlDiffuse"), model.material.diffuse[0], model.material.diffuse[1], model.material.diffuse[2])
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "mtlSpecular"), model.material.specular[0], model.material.specular[1], model.material.specular[2])
    gl.Uniform1f(gl.GetUniformLocation(model.shader.program, "mtlSpecularExponent"), model.material.specular_exponent)
    gl.ActiveTexture(gl.TEXTURE0 + tex_id)
    gl.BindTexture(gl.TEXTURE_2D, model.material.textures[0])
    

    gl.BindVertexArray(vao)
    gl.DrawElements(gl.TRIANGLES, i32(len(model.vertex_indices)), gl.UNSIGNED_INT, rawptr(uintptr(0)))
}


animate_planet :: proc(model: ^Model, system: ^System, vao: VAO, tex_id: u32, light_source_pos: linalg.Vector3f32, distance: f32, theta:f32, movement_speed: f32) {
    rotation_matrix := linalg.Matrix4x4f32{
        f32(math.cos(theta)),   0.0,  f32(math.sin(theta)),   0.0,
        0.0,                    1.0,  0.0,                    0.0,
        -f32(math.sin(theta)),  0.0,  f32(math.cos(theta)),  0.0,
        0.0,                    0.0,  0.0,                    1.0
        }

    gl.UseProgram(model.shader.program)
    model.m = linalg.identity_matrix(linalg.Matrix4x4f32)
    model.m = linalg.matrix4_translate_f32(linalg.Vector3f32({model.position[0],model.position[1],model.position[2]})) * model.m
    model.m = linalg.matrix4_rotate_f32(50, {1.0,0.0,0.0}) * model.m
    model.m *= rotation_matrix
    model.m = linalg.matrix4_translate_f32(linalg.Vector3f32({-distance * math.sin(theta*movement_speed), 0, distance * math.cos(theta*movement_speed)})) * model.m
    system.mvp = system.camera.p * system.camera.v
    system.mvp = system.mvp * model.m

    gl.UniformMatrix4fv(gl.GetUniformLocation(model.shader.program, "MVP"   ), 1, gl.FALSE, &system.mvp[0][0])
    gl.UniformMatrix4fv(gl.GetUniformLocation(model.shader.program, "model"   ), 1, gl.FALSE, &model.m[0][0])
    gl.UniformMatrix4fv(gl.GetUniformLocation(model.shader.program, "view"), 1, gl.FALSE, &system.camera.v[0][0])
    gl.UniformMatrix4fv(gl.GetUniformLocation(model.shader.program, "projection"), 1, gl.FALSE, &system.camera.p[0][0])
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "lightColor"), 1.0,1.0,1.0)
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "objectColor"), 0.5,0.7,0.9)
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "lightPos"), light_source_pos[0], light_source_pos[1], light_source_pos[2])
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "viewPos"), system.camera.position[0], system.camera.position[1], system.camera.position[2])
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "mtlAmbient"), model.material.ambient[0], model.material.ambient[1], model.material.ambient[2])
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "mtlDiffuse"), model.material.diffuse[0], model.material.diffuse[1], model.material.diffuse[2])
    gl.Uniform3f(gl.GetUniformLocation(model.shader.program, "mtlSpecular"), model.material.specular[0], model.material.specular[1], model.material.specular[2])
    gl.Uniform1f(gl.GetUniformLocation(model.shader.program, "mtlSpecularExponent"), model.material.specular_exponent)
    gl.ActiveTexture(gl.TEXTURE0 + tex_id)
    gl.BindTexture(gl.TEXTURE_2D, model.material.textures[0])
    

    gl.BindVertexArray(vao)
    gl.DrawElements(gl.TRIANGLES, i32(len(model.vertex_indices)), gl.UNSIGNED_INT, rawptr(uintptr(0)))
}

setup_model :: proc(model: Model, texture_path: string) -> (vao:VAO, texture:TEXTURE){
    texture = load_image(texture_path, model.material.texture_filename)
    vbo:VBO
    ebo:EBO

    gl.GenVertexArrays(1,&vao)
    gl.GenBuffers(1, &vbo)
    gl.GenBuffers(1, &ebo)

    gl.BindVertexArray(vao)
    stride1 := i32(size_of(Vertex))
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(model.vertex) * size_of(Vertex), raw_data(model.vertex), gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(model.vertex_indices) * size_of(u32), raw_data(model.vertex_indices), gl.STATIC_DRAW)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, stride1, offset_of(Vertex, vertex))
    gl.EnableVertexAttribArray(0)

    gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, stride1, offset_of(Vertex, texture))
    gl.EnableVertexAttribArray(1)

    gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, stride1, offset_of(Vertex, normal))
    gl.EnableVertexAttribArray(2)
    return vao, texture
}

move_model :: proc (model: ^Model, move_vector: linalg.Vector3f32){
    model.position += move_vector
    if(len(model.children) < 0){
        return
    }
    for c in model.children{
        c.position += move_vector
    }
}

scale_model :: proc (model: ^Model, scale_vector: linalg.Vector3f32){
    model.m = linalg.matrix4_scale_f32(scale_vector) * model.m
    if(len(model.children) < 0){
        return
    }
    for c in model.children{
        c.m = linalg.matrix4_scale_f32(scale_vector) * c.m
    }
}
