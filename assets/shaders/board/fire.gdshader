shader_type canvas_item;
uniform bool is_glowing = false;
uniform float fade_strength : hint_range(0.0, 1.0) = .7; // 1 = fully visible, 0 = fully faded
uniform vec2 screen_size; // <- You must set this from GDScript or inspector
uniform vec4 glow_color  = vec4(0.0, 0.0, 1.0, 1.0); // blue
uniform float speed = 0.5;
uniform float eff_intensity = 0.9;
uniform float radius = 0.7;

vec3 cmap(float x) {
    return pow(vec3(0.5 + 0.5 * cos(PI * x + 1.0),
                    0.5 + 0.5 * cos(PI * x + 2.0),
                    0.5 + 0.5 * cos(PI * x + 3.0)), vec3(2.5));
}

void fragment() {
	if (is_glowing) {
    vec2 uv = (2.0 * FRAGCOORD.xy - SCREEN_PIXEL_SIZE.xy) / SCREEN_PIXEL_SIZE.y;

    float focal = 3.25;
    vec3 ro = vec3(0.0, 0.0, 0.05 *TIME);
    vec3 rd = normalize(vec3(uv, -focal));

    vec3 color = vec3(0.0);
    float t = 0.0;

    // Loop to calculate the color
    for (int i = 0; i < 99; i++) {
        vec3 p = t * rd + ro;

        float T = (t + TIME) / 100.0;
        float c = cos(T);
        float s = sin(T);

        // Create the rotation matrix using vec2
        mat2 rotation = mat2(vec2(c, -s), vec2(s, c));
        p.xy = rotation * p.xy;

        for (float f = 0.0; f < 9.0; f++) {
            float a = exp(f) / exp2(f);
            p += cos(p.yzx * a + TIME) / a;
        }

        float d = 1.0 / 50.0 + abs((ro - p - vec3(0.0, 1.0, 0.0)).y - 1.0) / 10.0;
        color += cmap(t) * 2e-3 / d;
        t += d;
    }

    // Adjusting the color brightness and applying gamma correction
    color *= color * color;
    //color = 1.0 - exp(-color);
    color = pow(color, vec3(.5 / 2.2));
    // Fade out at the top
// Fade effect at the top of the UV (from bottom [0.0] to top [1.0])
float top_fade = smoothstep(0.1, 0.3, UV.y); // fades out between 70% and 100% height

// Apply 70% overall alpha and fade
float effect_alpha = 0.7 * top_fade *fade_strength;
float intensity = length(color); // total brightness
if (intensity < 0.3) {
    discard; // make very dark parts fully transparent
}
vec2 uv2 = FRAGCOORD.xy / screen_size;
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv2, center);

    float time = TIME * speed;
    float pulse = sin(time * 00.2831) * 0.3 + 0.6; // 0..1 pulsing
    float edge = smoothstep(radius, radius - 0.2, dist);

    float alpha = (1.0 - edge) * pulse * eff_intensity;

    //COLOR = glow_color * alpha;
// Final color with effect-only transparency
COLOR = vec4(color, effect_alpha)* alpha;
}else{
	COLOR = vec4(0.0,0.0,0.0, 0.0);
}
}
