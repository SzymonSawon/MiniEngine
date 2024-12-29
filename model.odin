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

CollisionBox :: struct {
    min_local: linalg.Vector3f32,
    max_local: linalg.Vector3f32,

    aabb_min: linalg.Vector3f32,
    aabb_max: linalg.Vector3f32,
}

ModelData :: struct {
    vertices : [dynamic]Vertex,
    vertices_indices : [dynamic]u32,
    material: Material,
    collision_box: CollisionBox,
}
Material :: struct{
    ambient: linalg.Vector3f32,
    diffuse: linalg.Vector3f32,
    specular: linalg.Vector3f32,
    specular_exponent: f32,
    texture_filename: string,
    textures: [dynamic]TEXTURE
}

read_obj_only :: proc(filepath: string) -> ModelData {
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
    m: linalg.Matrix4f32

    min_x, min_y, min_z := f32(100000.0), f32(100000.0), f32(100000.0)
    max_x, max_y, max_z := f32(-100000.0), f32(-100000.0), f32(-100000.0)

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
        
                if a < min_x { min_x = a }
                if b < min_y { min_y = b }
                if c < min_z { min_z = c }
                if a > max_x { max_x = a }
                if b > max_y { max_y = b }
                if c > max_z { max_z = c }

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
    collision_box_value := CollisionBox{
        min_local = linalg.Vector3f32{min_x, min_y, min_z},
        max_local = linalg.Vector3f32{max_x, max_y, max_z},
        aabb_min  = {},
        aabb_max  = {},
    }


    model_data := ModelData{
        vertices         = model_vertices,
        vertices_indices = model_indices,
        material         = Material{
            ambient            = model_ambient,
            diffuse            = model_diffuse,
            specular           = model_specular,
            specular_exponent  = model_spec_exp,
            texture_filename   = texture_filename,
            textures           = material_textures,
        },
        collision_box    = collision_box_value,
    }
    return model_data
}

setup_model_object :: proc(model_data: ModelData, texture_path: string) -> (vao:VAO, texture:TEXTURE){
    texture = load_image(texture_path, model_data.material.texture_filename)
    vbo:VBO
    ebo:EBO

    gl.GenVertexArrays(1,&vao)
    gl.GenBuffers(1, &vbo)
    gl.GenBuffers(1, &ebo)

    gl.BindVertexArray(vao)
    stride1 := i32(size_of(Vertex))
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, len(model_data.vertices) * size_of(Vertex), raw_data(model_data.vertices), gl.STATIC_DRAW)

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(model_data.vertices_indices) * size_of(u32), raw_data(model_data.vertices_indices), gl.STATIC_DRAW)

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, stride1, offset_of(Vertex, vertex))
    gl.EnableVertexAttribArray(0)

    gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, stride1, offset_of(Vertex, texture))
    gl.EnableVertexAttribArray(1)

    gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, stride1, offset_of(Vertex, normal))
    gl.EnableVertexAttribArray(2)
    return vao, texture
}

draw_model_object :: proc(
    object: ^Object, 
    system: ^System, 
    vao: VAO, 
    tex_unit: u32,
    light_source_pos: linalg.Vector3f32
) {
    gl.UseProgram(object.shader.program)

    model_mat:linalg.Matrix4f32 = object.w 
    mvp :linalg.Matrix4f32 = system.p * system.v * model_mat

    gl.UniformMatrix4fv(gl.GetUniformLocation(object.shader.program, "MVP"),       1, gl.FALSE, &mvp[0][0])
    gl.UniformMatrix4fv(gl.GetUniformLocation(object.shader.program, "model"),    1, gl.FALSE, &model_mat[0][0])
    gl.UniformMatrix4fv(gl.GetUniformLocation(object.shader.program, "view"),     1, gl.FALSE, &system.v[0][0])
    gl.UniformMatrix4fv(gl.GetUniformLocation(object.shader.program, "projection"), 1, gl.FALSE, &system.p[0][0])

    gl.Uniform3f(gl.GetUniformLocation(object.shader.program, "lightColor"), 1.0,1.0,1.0)
    gl.Uniform3f(gl.GetUniformLocation(object.shader.program, "objectColor"), 0.5,0.7,0.9)
    gl.Uniform3f(gl.GetUniformLocation(object.shader.program, "lightPos"), light_source_pos[0], light_source_pos[1], light_source_pos[2])
    gl.Uniform3f(gl.GetUniformLocation(object.shader.program, "viewPos"), system.camera.position[0], system.camera.position[1], system.camera.position[2])

    gl.Uniform3f(gl.GetUniformLocation(object.shader.program, "mtlAmbient"),
        object.model_data.material.ambient[0],
        object.model_data.material.ambient[1],
        object.model_data.material.ambient[2]
    )
    gl.Uniform3f(gl.GetUniformLocation(object.shader.program, "mtlDiffuse"),
        object.model_data.material.diffuse[0],
        object.model_data.material.diffuse[1],
        object.model_data.material.diffuse[2]
    )
    gl.Uniform3f(gl.GetUniformLocation(object.shader.program, "mtlSpecular"),
        object.model_data.material.specular[0],
        object.model_data.material.specular[1],
        object.model_data.material.specular[2]
    )
    gl.Uniform1f(gl.GetUniformLocation(object.shader.program, "mtlSpecularExponent"),
        object.model_data.material.specular_exponent
    )

    if len(object.model_data.material.textures) > 0 {
        gl.ActiveTexture(gl.TEXTURE0 + tex_unit)
        gl.BindTexture(gl.TEXTURE_2D, object.model_data.material.textures[0])
    }

    gl.BindVertexArray(vao)
    gl.DrawElements(gl.TRIANGLES, i32(len(object.model_data.vertices_indices)), gl.UNSIGNED_INT, rawptr(uintptr(0)))
}
