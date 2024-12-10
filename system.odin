package engine
import "core:math/linalg"
import "core:strings"
import "core:strconv"
import "core:fmt"
import "core:os"
import "vendor:glfw"
import gl "vendor:OpenGL"


System :: struct{
    camera: Camera,
    mvp: linalg.Matrix4f32,
    width, height: i32,
}

Camera :: struct{
    position : linalg.Vector3f32,
    yaw,pitch,fov : f32,
    v, p: linalg.Matrix4f32
}
