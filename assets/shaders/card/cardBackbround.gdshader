shader_type canvas_item;

// Tint colors
uniform vec4 mana_color1 = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 mana_color2 = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 mana_color3 = vec4(1.0, 1.0, 1.0, 1.0);

// Tint weights
uniform float weight1 = 1.0;
uniform float weight2 = 0.0;
uniform float weight3 = 0.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    if (tex_color.a > 0.0) {
        float total_weight = max(weight1 + weight2 + weight3, 0.001);
        vec3 tint = (
            mana_color1.rgb * weight1 +
            mana_color2.rgb * weight2 +
            mana_color3.rgb * weight3
        ) / total_weight;

        vec3 tinted_rgb = tex_color.rgb * tint;
        COLOR = vec4(tinted_rgb, tex_color.a);
    } else {
        COLOR = vec4(0.0);
    }
}
