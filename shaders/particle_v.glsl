#version 330 core
layout (location = 0) in vec3 position;
layout (location = 0) in vec4 color;

out vec2 TexCoords;
out vec4 ParticleColor;

//uniform mat4 model;
uniform mat4 projection;
uniform vec3 offset;
uniform vec4 color;

void main(){
    float scale = 15.0f;
    TexCoords = vertex.zw;
    ParticleColor = color;
    //gl_Position = projection  * model *  vec4(vertex.xy, 0.0, 1.0);
    gl_Position = projection * vec4((vertex.xy * scale) + offset, 0.0, 1.0);
}
