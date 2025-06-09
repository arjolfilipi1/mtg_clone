shader_type canvas_item;
uniform bool ss = false;
uniform vec4 overlay_color : source_color = vec4(1.0, 0.0, 0.0, 0.4); // Red tint with some transparency
uniform float pulse_speed = 5.0; // Speed of the pulse effect
uniform float pulse_strength = 0.4; // Intensity of pulsing

void fragment() {
if (ss) {   
 vec4 tex_color = texture(TEXTURE, UV);

float pulse = sin(TIME * pulse_speed) * 0.3 + 0.7; // 0..1
    float alpha = pulse * pulse_strength;

    COLOR = vec4(overlay_color.rgb, alpha);
	}else{
		COLOR = vec4(COLOR[0],COLOR[1],COLOR[2], 0.0);
	}
}
