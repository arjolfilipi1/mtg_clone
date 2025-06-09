shader_type canvas_item;

uniform vec2 screen_size; // <- You must set this from GDScript or inspector
uniform vec4 glow_color  = vec4(0.0, 0.0, 1.0, 1.0); // blue
uniform float speed = 2.0;
uniform float eff_intensity = 1.5;
uniform float radius = 0.5;

void fragment() {
    vec2 uv = FRAGCOORD.xy / screen_size;
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);

    float time = TIME * speed;
    float pulse = sin(time * 6.2831) * 0.5 + 0.5; // 0..1 pulsing
    float edge = smoothstep(radius, radius - 0.2, dist);

    float alpha = (1.0 - edge) * pulse * eff_intensity;

    COLOR = glow_color * alpha;
}
