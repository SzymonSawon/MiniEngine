package engine
import "core:math/linalg"
import "core:strings"
import "core:strconv"
import "core:fmt"
import "core:os"
import "vendor:glfw"
import gl "vendor:OpenGL"
import "core:image"
import "core:math"
import png "core:image/png"


load_image :: proc(filepath, filename:string) -> TEXTURE{
    full_path:string = strings.concatenate({filepath, filename})
    image_ptr: ^image.Image
    err: image.Error
    options := image.Options{}
    image_ptr, err = png.load_from_file(full_path, options)
    image_w := i32(image_ptr.width)
    image_h := i32(image_ptr.height)
    if err != nil {
        fmt.print("ERROR: Image: ", full_path, " failed to load.")
        return 0
    }
    image_pixels := make([]u8, len(image_ptr.pixels.buf))
    for b, i in image_ptr.pixels.buf {
        image_pixels[i] = b
    }

    row_size := image_w * 4
    flipped_pixels := make([]u8, len(image_pixels))
    for y in 0..<image_h {
        src_row_start := y * row_size
        dest_row_start := (image_h - 1 - y) * row_size
        for x in 0..<row_size {
            flipped_pixels[dest_row_start + x] = image_pixels[src_row_start + x]
        }
    }

    texture : TEXTURE
    gl.GenTextures(1, &texture)
    gl.BindTexture(gl.TEXTURE_2D, texture)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    gl.TexImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA,
        image_w,
        image_h,
        0,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        &flipped_pixels[0]
    )
    gl.GenerateMipmap(gl.TEXTURE_2D)
    return texture
}
