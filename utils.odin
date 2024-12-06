package engine
import "core:math/linalg"
import "core:strings"
import "core:strconv"
import "core:fmt"
import "core:os"
import "vendor:glfw"
import gl "vendor:OpenGL"

Vertex :: struct {
    vertex:linalg.Vector3f32,
    texture:linalg.Vector2f32,
    normal:linalg.Vector3f32,
}
ColorVertex :: struct {
    position: linalg.Vector3f32,
    normal:   linalg.Vector3f32,
    color:    linalg.Vector3f32
}


index_of :: proc(array: []i64, value: i64) -> int {
    for i in 0..<len(array){
        if array[i] == value{
            return i
        }
    }
    return -1
}


vertex_equals :: proc (v1, v2:Vertex) -> bool{
    if(v1.vertex[0] != v2.vertex[0]){
        return false
    }
    if(v1.vertex[1] != v2.vertex[1]){
        return false
    }
    if(v1.vertex[2] != v2.vertex[2]){
        return false
    }

    if(v1.normal[0] != v2.normal[0]){
        return false
    }
    if(v1.normal[1] != v2.normal[1]){
        return false
    }
    if(v1.normal[2] != v2.normal[2]){
        return false
    }

    if(v1.texture[0] != v2.texture[0]){
        return false
    }
    if(v1.texture[1] != v2.texture[1]){
        return false
    }
    return true
}


find_element :: proc(array: [dynamic]Vertex, element: Vertex) -> int{
    for i in 0..<len(array){
        if(vertex_equals(array[i], element)){
            return i
        }
    }
    return -1
}
