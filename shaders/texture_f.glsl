#version 330 core
out vec4 FragColor;

in vec3 Normal;
in vec3 FragPos;
in vec2 TexCoords;

uniform vec3 lightPos;
uniform vec3 viewPos;
uniform vec3 lightColor;
uniform vec3 objectColor;
uniform vec3 mtlAmbient;
uniform vec3 mtlDiffuse;
uniform vec3 mtlSpecular;
uniform float mtlSpecularExponent;
uniform sampler2D texture1;

void main()
{
    float ambientStrength = 0.3;
    vec3 ambient = ambientStrength * mtlAmbient;

    vec3 norm = normalize(Normal);
    //l = P_0-P_1
    vec3 lightDir = normalize(lightPos - FragPos);
    //k = l*n
    float diff = max(dot(norm, lightDir), 0.0);
    //diffuse = k*l_d
    vec3 diffuse = diff * mtlDiffuse;


    //Blinn-Phong
    //vec3 halfwayDir = normalize(lightDir + viewDir);
    //float spec = pow(max(dot(norm, halfwayDir), 0.0), mtlSpecularExponent);
    float specularStrength = 0.5f;
    //l = P_0-P_1
    vec3 viewDir = normalize(viewPos - FragPos);
    //r = l - 2.0 * dot(n, l) * n
    vec3 reflectDir = reflect(-lightDir, norm);
    //k = dot(r,v)^alpha
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    //specular = spec_strength * l * k
    vec3 specular = specularStrength * spec * mtlSpecular;

    vec3 texColor = texture(texture1, TexCoords).xyz;
    vec3 result = (ambient + diffuse  * texColor + specular);

    FragColor = vec4(result, 1.0);
}
