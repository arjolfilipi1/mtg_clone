shader_type canvas_item;

// Uniforms - these can be adjusted in the inspector
uniform vec4 base_color : source_color = vec4(0.8, 1.0, 0.1, 1.0); // Button base color
uniform vec4 glow_color : source_color = vec4(0.9, 0.0, 0.05, 1.0); // Glow color
uniform float glow_intensity : hint_range(0, 5) = 0.8; // Base glow strength
uniform float hover_glow_boost : hint_range(0, 5) = 1.5; // Additional glow when hovered
uniform float pulse_speed : hint_range(0, 5) = 3.0; // Speed of pulse animation
uniform float pulse_amount : hint_range(0, 1) = 0.1; // Amount of pulse variation

// Hover state (set this from your button script)
uniform float hover_ratio : hint_range(0, 1) = 0.0;

void fragment() {
    // Get texture color
	if (hover_ratio > 0.0){
    vec4 tex_color = texture(TEXTURE, UV);

    // Calculate glow factor with pulse animation
    float time_pulse = sin(TIME * pulse_speed) * pulse_amount;
    float glow_factor = glow_intensity * (1.0 + time_pulse)-0.2;

    // Boost glow when hovered
    glow_factor += hover_ratio * hover_glow_boost;

    // Create glow effect
    vec4 glow = glow_color * glow_factor * tex_color.a;

    // Mix base color with glow
    vec4 final_color = mix(base_color * tex_color, glow, glow_factor);

    // Ensure we don't exceed reasonable brightness
    final_color = clamp(final_color, vec4(0.0), vec4(1.0));

    COLOR = final_color;
}
}