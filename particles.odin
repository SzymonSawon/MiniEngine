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
import "core:math/rand"

Particle :: struct {
    position, velocity: linalg.Vector3f32,
    color: linalg.Vector3f32,
    life: f32,
}

respawn_particle :: proc(particle: ^Particle, model: ^Model){
    random_pos := linalg.Vector3f32{
         rand.float32_range(-5.0, 5.0),
         rand.float32_range(-5.0, 5.0),
         rand.float32_range(-5.0, 5.0)
    }
    particle.position = model.position + random_pos
    particle.color = linalg.Vector3f32({0.6,0.3,0.8})
    particle.life = 1.0
    particle.velocity = linalg.Vector3f32{
        rand.float32_range(0.1, 0.5),
        rand.float32_range(0.1, 0.5),
        rand.float32_range(0.1, 0.5),
    }
}



update_particles :: proc(particles: [dynamic]Particle, theta: f32, model: ^Model, vbo, particle_vbo: VBO) -> [dynamic]Particle{
    data:[dynamic]Particle
    vbo: VBO
    for i := 1; i<=len(particles); i+=1 {
        particles[i].position = particles[i].position + particles[i].velocity * theta

        particles[i].life -= theta

        if particles[i].life <= 0.0 {
            respawn_particle(&particles[i], model)
        }

        factor := 1.0 - particles[i].life 
        particles[i].color = linalg.Vector3f32{
            1.0 - factor,
            factor,
            0.0,
        }
        append(&data, particles[i])
    }
    //gl.BindBuffer(gl.ARRAY_BUFFER, particles)
    //gl.BufferData(gl.ARRAY_BUFFER, len(particle)*size_of(particle), raw_data(particles), gl.STATIC_DRAW)
    //gl.BufferSubData(gl.ARRAY_BUFFER, len(particles) * size_of(Particle), raw_data(particles))
    return data
}

render_particles :: proc (particles: [dynamic]Particle, model: ^Model, shader_program: PROGRAM, tex_count: u32, vbo: VBO, theta: f32) {
    gl.UseProgram(shader_program)

    gl.ActiveTexture(gl.TEXTURE0 + tex_count)
    gl.BindTexture(gl.TEXTURE_2D, tex_count)

    //update_particles(particles, theta, model)
    vao: VAO
    gl.BindVertexArray(vao)
    gl.DrawArraysInstanced(gl.POINTS, 0, 1, i32(len(particles)))
}

init_particles :: proc (particle_count: i32, model: ^Model) -> [dynamic]Particle{
    particle: Particle
    particles: [dynamic]Particle
    for i in 0..<particle_count{
        random_pos := linalg.Vector3f32{
             rand.float32_range(-5.0, 5.0),
             rand.float32_range(-5.0, 5.0),
             rand.float32_range(-5.0, 5.0)
        }
        particle.position = model.position + random_pos
        particle.color = linalg.Vector3f32({0.6,0.3,0.8})
        particle.life = 1.0
        particle.velocity = linalg.Vector3f32{
            rand.float32_range(0.1, 0.5),
            rand.float32_range(0.1, 0.5),
            rand.float32_range(0.1, 0.5),
        }
        append(&particles, particle)
    }
    shader_program: PROGRAM
    program_ok: bool
    vertex_shader   := string(#load("shaders/particle_v.glsl"  ))
    fragment_shader := string(#load("shaders/particle_f.glsl"))
    shader_program, program_ok = gl.load_shaders_source(vertex_shader, fragment_shader)
    vbo, billboard_vb: VBO

    //gl.GenBuffers(1, &billboard_vb)
    //gl.BindBuffer(gl.ARRAY_BUFFER, billboard_vb)
    //gl.BufferData(gl.ARRAY_BUFFER, size_of(particle), particle, gl.STATIC_DRAW)

    //gl.GenBuffers(1, &particles)
    //gl.BindBuffer(gl.ARRAY_BUFFER, particles)
    //gl.BufferData(gl.ARRAY_BUFFER, len(particle)*size_of(particle), raw_data(particles), gl.STATIC_DRAW)

    stride1 := i32(size_of(Particle))
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, stride1, offset_of(Particle, position))
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, stride1, offset_of(Particle, color))
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, stride1, offset_of(Particle, velocity))
    gl.EnableVertexAttribArray(0)
    return particles
}
