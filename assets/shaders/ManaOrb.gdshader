shader_type canvas_item;

uniform vec4 glow_color = vec4(0.6, 0.8, 1.0, 1.0); // bluish storm glow
uniform float glow_strength = 1.5;
uniform float pulse_speed = 2.5;
uniform float pulse_amplitude = 0.5;
uniform float noise_scale = 8.0;
uniform float flicker_intensity = 0.3;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// 2D noise based on hashing
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV - vec2(0.5);

    // Radial distance
    float dist = length(uv * 2.0);
    float base_alpha = smoothstep(0.5, 0.0, dist);

    // Pulse
    float pulse = 1.5 + sin(TIME * pulse_speed) * pulse_amplitude;

    // Noise-based flicker
    float n = noise(UV * noise_scale + vec2(TIME * 0.5, TIME * 0.3));
    float flicker = mix(1.0, 1.0 + flicker_intensity, n);

    float final_alpha = base_alpha * glow_strength * pulse * flicker;

    COLOR = vec4(glow_color.rgb, final_alpha * glow_color.a);
}
