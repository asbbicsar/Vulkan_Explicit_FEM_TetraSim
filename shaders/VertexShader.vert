#version 450

layout(binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

struct PhysicsVertex {
    vec3 pos;
    float invMass;
    vec3 vel;
    float padding;
    vec4 normal;
};

struct RenderVertex {
    vec4 color;
};

struct Force {
    vec3 force;
    float stress;
};

layout(std430, binding = 1) readonly buffer PhysicsBuffer { PhysicsVertex physicsVerts[]; };
layout(std430, binding = 2) readonly buffer RenderBuffer { RenderVertex renderVerts[]; };
layout(std430, binding = 3) readonly buffer ForceBuffer { Force forces[]; };

layout(push_constant) uniform PushConstants {
    float dt;
    float u_Time;
    uint numWorkGroupsFromPreviousPass;
    float youngsModulus;
    float poissonsRatio;
    uint colorOffset;
    uint colorCount;
} pc;

layout(location = 0) out vec3 fragColor;




vec3 getHeatmapColor(float value) {
    value = clamp(value, 0.0, 1.0);
    vec3 blue  = vec3(0.0, 0.0, 1.0);
    vec3 green = vec3(0.0, 1.0, 0.0);
    vec3 red   = vec3(1.0, 0.0, 0.0);
    
    // 0.0 ~ 0.5 구간: 파랑 -> 초록
    vec3 color = mix(blue, green, smoothstep(0.0, 0.5, value));
    // 0.5 ~ 1.0 구간: 초록 -> 빨강
    color = mix(color, red, smoothstep(0.5, 1.0, value));
    
    return color;
}

void main() {
    gl_PointSize = 3.0;
    gl_Position = ubo.proj * ubo.view * ubo.model * vec4(physicsVerts[gl_VertexIndex].pos, 1.0);
    
    float stress = forces[gl_VertexIndex].stress;
    
    float maxStress = 250.0; // tuning needed
    float normalizedStress = clamp(stress / maxStress, 0.0, 1.0);
    
    vec3 heatmapColor = getHeatmapColor(normalizedStress);
    
    // vec3 baseColor = renderVerts[gl_VertexIndex].color.xyz;
    // fragColor = mix(baseColor, heatmapColor, 0.8); 
    
    fragColor = heatmapColor;
}
