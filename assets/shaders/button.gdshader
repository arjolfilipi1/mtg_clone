shader_type canvas_item;

// Uniforms - these can be adjusted in the inspector
uniform vec4 base_color : source_color = vec4(0.8, 1.0, 0.1, 1.0); // Button base color
uniform vec4 glow_color : source_color = vec4(0.9, 0.0, 0.05, 1.0); // Glow color
uniform float glow_intensity : hint_range(0, 5) = 0.8; // Base glow strength
uniform float hover_glow_boost : hint_range(0, 5) = 1.5; // Additional glow when hovered
uniform float pulse_speed : hint_range(0, 5) = 3.0; // Speed of pulse animation
uniform float pulse_amount : hint_range(0, 1) = 0.1; // Amount of pulse variation

// White detection threshold
uniform float white_threshold : hint_range(0, 1) = 0.9; // How close to pure white to affect

// Hover state (set this from your button script)
uniform float hover_ratio : hint_range(0, 1) = 0.0;

void fragment() {
    // Get original texture color
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Check if this pixel is white (or near white)
    float whiteness = (tex_color.r + tex_color.g + tex_color.b) / 3.0;
    float is_white = step(white_threshold, whiteness) * tex_color.a;
    
    // Only apply effects if pixel is white and we have some hover ratio
    if (is_white > 0.0 && hover_ratio > 0.0) {
        // Calculate glow factor with pulse animation
        float time_pulse = sin(TIME * pulse_speed) * pulse_amount;
        float glow_factor = glow_intensity * (1.0 + time_pulse) - 0.2;

        // Boost glow when hovered
        glow_factor += hover_ratio * hover_glow_boost;

        // Create glow effect
        vec4 glow = glow_color * glow_factor * tex_color.a;

        // Mix base color with glow, but only apply to white parts
        vec4 final_color = mix(base_color * tex_color, glow, glow_factor);

        // Ensure we don't exceed reasonable brightness
        final_color = clamp(final_color, vec4(0.0), vec4(1.0));

        // Only replace the white parts, keep original for non-white
        COLOR = mix(tex_color, final_color, is_white);
    } else {
        // Keep original texture color for non-white pixels or no hover
        COLOR = tex_color;
    }
}