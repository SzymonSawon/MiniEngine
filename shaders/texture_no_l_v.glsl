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
uniform float time;

void main()
{
    float distortionAmount = 0.8;
    float distortionSpeed = 1.0;

    float offsetX = sin(time * distortionSpeed + vPos.y * 0.5) * distortionAmount;
    float offsetY = cos(time * distortionSpeed + vPos.x * 0.5) * distortionAmount;
    float offsetZ = sin(time * distortionSpeed * 0.5 + vPos.x * 0.5) * distortionAmount;

    vec3 distortedPos = vPos + vec3(offsetX, offsetY, offsetZ);

    FragPos = vec3(model * vec4(distortedPos, 1.0));
    Normal = mat3(transpose(inverse(model))) * aNormal;
    TexCoords = texCoords;

    gl_Position = MVP * vec4(distortedPos, 1.0);
}

