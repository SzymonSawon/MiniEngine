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

update_particles :: proc(particles: [dynamic]Particle, theta: f32, model: ^Model) {
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
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, len(data) * size_of(Particle), raw_data(data))
}

render_particles :: proc (particles: [dynamic]Particle, model: ^Model, shader_program: PROGRAM, tex_count: u32, vbo: VBO, theta: f32) {
    gl.UseProgram(shader_program)

    gl.ActiveTexture(gl.TEXTURE0 + tex_count)
    gl.BindTexture(gl.TEXTURE_2D, tex_count)

    update_particles(particles, theta, model)
    vao: VAO
    gl.BindVertexArray(vao)
    gl.DrawArraysInstanced(gl.POINTS, 0, 1, i32(len(particles)))
}

init_particles :: proc (particle_count: i32, model: ^Model) -> [dynamic]Particle{
    particle: Particle
    particles: [dynamic]Particle
    for i in 0..<particle_count{
        respawn_particle(&particle, model)
        append(&particles, particle)
    }
    return particles
}
