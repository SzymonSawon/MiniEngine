package engine
//import stbi "vendor:stb/image"


//load_image ::proc(filepath:string) -> Texture {
//
//
//    width, height, nr_channels: i32
//    stbi.set_flip_vertically_on_load(1)
//    data:= stbi.load("./fish_2_tex.png", &width, &height, &nr_channels, 3)
//    assert(data != nil)
//
//    texture : Texture
//    gl.GenTextures(1, &texture)
//    gl.BindTexture(gl.TEXTURE_2D, texture)
//
//    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
//    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
//    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
//    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
//
//
//    gl.TexImage2D(
//        gl.TEXTURE_2D,
//        0,
//        gl.RGB,
//        width,
//        width,
//        0,
//        gl.RGB,
//        gl.UNSIGNED_BYTE,
//        &data[0]
//    )
//    gl.GenerateMipmap(gl.TEXTURE_2D)
//    return texture
//}
