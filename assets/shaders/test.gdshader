shader_type canvas_item;

uniform float grayscale_amount : hint_range(0.0, 1.0) = 0.0;
uniform float alpha_override : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
    tex_color.rgb = mix(tex_color.rgb, vec3(gray), grayscale_amount);
    tex_color.a *= alpha_override;

    COLOR = tex_color;
}