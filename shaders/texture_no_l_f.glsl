#version 330 core

out vec4 FragColor;

in vec2 TexCoords;

uniform sampler2D texture1;
uniform float time;

void main()
{
    vec4 textureColor = texture(texture1, TexCoords);

    float red = (sin(time * 1.0) + 1.0) / 2.0;
    float green = (cos(time * 0.8) + 1.0) / 2.0;
    float blue = 0.0; 

    FragColor = textureColor * vec4(red, green, blue, 1.0);
}
