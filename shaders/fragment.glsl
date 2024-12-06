#version 330 core
out vec4 FragColor;

in vec3 Normal;
in vec3 FragPos;

uniform vec3 lightPos;
uniform vec3 viewPos;
uniform vec3 lightColor;
uniform vec3 objectColor;

void main()
{
    float ambientStrength = 0.3;
    vec3 ambient = ambientStrength * lightColor;

    vec3 norm = normalize(Normal);
    //l = P_0-P_1
    vec3 lightDir = normalize(lightPos - FragPos);
    //k = l*n
    float diff = max(dot(norm, lightDir), 0.0);
    //diffuse = k*l_d
    vec3 diffuse = diff * lightColor;


    //Blinn-Phong
    //vec3 halfwayDir = normalize(lightDir + viewDir);
    //float spec = pow(max(dot(norm, halfwayDir), 0.0), 64.0);
    float specularStrength = 0.5f;
    //l = P_0-P_1
    vec3 viewDir = normalize(viewPos - FragPos);
    //r = l - 2.0 * dot(n, l) * n
    vec3 reflectDir = reflect(-lightDir, norm);
    //k = dot(r,v)^alpha
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    //specular = spec_strength * l * k
    vec3 specular = specularStrength * spec * lightColor;

    //m = objectColor (same for each light)
    vec3 result = (ambient + diffuse + specular) * objectColor;
    FragColor = vec4(result, 1.0);
}
