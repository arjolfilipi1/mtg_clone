shader_type canvas_item;
uniform bool is_dragging = false;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    if (is_dragging) {
        float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
        tex_color.rgb = vec3(gray);
        tex_color.a *= 0.5;
    }else{
		tex_color.a = 1.0;
	}
    COLOR = tex_color;
}
