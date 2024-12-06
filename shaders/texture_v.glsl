#version 330 core
layout(location = 0) in vec3 vPos;
layout(location = 1) in vec2 texCoords;
layout(location = 2) in vec3 aNormal;

out vec2 TexCoords;
out vec3 FragPos;
out vec3 Normal;

uniform mat4 MVP;
uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    FragPos = vec3(model * vec4(vPos, 1.0));
    Normal = mat3(transpose(inverse(model))) * aNormal;
    TexCoords = texCoords;
    gl_Position = MVP * vec4(vPos, 1.0);
}
