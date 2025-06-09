shader_type canvas_item;

const float P = 3.14159265;

vec3 cmap(float x) {
    return pow(vec3(0.5 + 0.5 * cos(P * x + 1.0),
                    0.5 + 0.5 * cos(P * x + 2.0),
                    0.5 + 0.5 * cos(P * x + 3.0)), vec3(2.5));
}

void fragment() {
    vec2 uv = (2.0 * FRAGCOORD.xy - SCREEN_PIXEL_SIZE.xy) / SCREEN_PIXEL_SIZE.y;
    float focal = 1.25;
    vec3 ro = vec3(0.0, 0.0, TIME);
    vec3 rd = normalize(vec3(uv, -focal));
    vec3 color = vec3(0.0);
    float t = 0.0;

    for (float a = 0.5, t = 0.5, i = 1.0; i < 19.0; i++) {
        vec3 p = t * rd + ro;
        float T = (t + TIME) / 10000.0;
        float c = cos(T);
        float s = sin(T);

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

    color *= color * color;
    color = 1.0 - exp(-color);
    color = pow(color, vec3(1.0 / 2.2));

    // Manually set alpha to 1.0
    COLOR = vec4(color, 1.0);
}
