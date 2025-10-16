shader_type canvas_item;
render_mode blend_premul_alpha;

// Toggle uniform
uniform bool Enable_Effects = false;

// Highlight effect uniforms
uniform float Line_Smoothness : hint_range(0, 0.1) = 0.045;
uniform float Line_Width : hint_range(0, 0.2) = 0.2;
uniform float Brightness = 3.0;
uniform float Rotation_deg : hint_range(-90, 90) = 30;
uniform float Distortion : hint_range(1, 2) = 1.8;
uniform float Speed = 0.7;
uniform float Position : hint_range(0, 1) = 0;
uniform float Position_Min = 0.25;
uniform float Position_Max = 0.5;
uniform float Alpha : hint_range(0, 1) = 1;

// Border controls
uniform vec4 Border_Color  = vec4(1.0, 1.0, 1.0, 1.0);
uniform float Border_Width : hint_range(0, 0.1) = 0.02;
uniform float Border_Feather : hint_range(0, 0.05) = 0.01;
uniform float Border_Alpha : hint_range(0, 1) = .7;
uniform bool Border_Fade_Inwards = true;
uniform bool Enable_Border = true;

void fragment() {
    // Get the original texture color
    vec4 tex_color = texture(TEXTURE, UV);
    vec4 final_color = tex_color;

    // Early return if effects are disabled
    if (!Enable_Effects) {
        COLOR = vec4(0.0);

    }

    // Only apply effects if the texture has some alpha (is visible)
    if (tex_color.a > 0.0) {
        // BORDER EFFECT
        if (Enable_Border) {
            vec2 pixel_size = 1.0 / TEXTURE_PIXEL_SIZE;

            // Sample neighboring pixels
            float center = tex_color.a;
            float top = texture(TEXTURE, UV + vec2(0.0, -pixel_size.y)).a;
            float bottom = texture(TEXTURE, UV + vec2(0.0, pixel_size.y)).a;
            float left = texture(TEXTURE, UV + vec2(-pixel_size.x, 0.0)).a;
            float right = texture(TEXTURE, UV + vec2(pixel_size.x, 0.0)).a;

            // Calculate edge gradient
            float edge = max(max(top, bottom), max(left, right)) - center;

            if (Border_Fade_Inwards) {
                // Inward fading border
                float border_mask = smoothstep(0.0, Border_Width + Border_Feather, edge);
                border_mask = 1.0 - smoothstep(Border_Width, Border_Width + Border_Feather, edge);
                vec4 border = Border_Color * border_mask * Border_Alpha;
                final_color = mix(final_color, border, border.a);
            } else {
                // Outward fading border
                float border_mask = smoothstep(0.0, Border_Feather, edge);
                border_mask *= smoothstep(Border_Width + Border_Feather, Border_Width, edge);
                vec4 border = Border_Color * border_mask * Border_Alpha;
                final_color = mix(final_color, border, border.a);
            }
        }

        // HIGHLIGHT EFFECT
        vec2 center_uv = UV - vec2(0.5, 0.5);
        float gradient_to_edge = max(abs(center_uv.x), abs(center_uv.y));
        gradient_to_edge = gradient_to_edge * Distortion;
        gradient_to_edge = 1.0 - gradient_to_edge;

        float rotation_radians = radians(Rotation_deg);
        mat2 rotation_matrix = mat2(
            vec2(cos(rotation_radians), sin(rotation_radians)),
            vec2(-sin(rotation_radians), cos(rotation_radians))
        );
        vec2 rotated_uv = rotation_matrix * center_uv;

        float output_range = Position_Max - Position_Min;
        float remapped_position = Position_Min + output_range * Position;
        float remapped_time = fract(TIME * Speed + remapped_position);
        remapped_time = -2.0 + 4.0 * remapped_time;

        vec2 offset_uv = rotated_uv + vec2(remapped_time, 0.0);
        float line = abs(offset_uv.x);
        line = gradient_to_edge * line;
        line = sqrt(line);

        float line_smoothness = clamp(Line_Smoothness, 0.001, 1.0);
        float offset_plus = Line_Width + line_smoothness;
        float offset_minus = Line_Width - line_smoothness;

        float remapped_line = (line - offset_plus) / (offset_minus - offset_plus);
        remapped_line = clamp(remapped_line, 0.0, 1.0);

        final_color.rgb += remapped_line * vec3(1.0) * Brightness;
    }

    // Apply alpha uniform
    final_color.a *= 0.0;
	if (Enable_Effects) {
    COLOR = final_color;}
}