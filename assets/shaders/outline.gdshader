shader_type canvas_item;

uniform float border_width = 0.02; // Border thickness in UV space
uniform float blur = 0.01; // Blur amount for all edges (0.0 = sharp, >0.0 = softer)
uniform float corner_radius = 0.05; // Corner radius in UV space (0.0 = sharp, >0.0 = rounded)
uniform float dash_length = 0.1; // Length of each dash in UV space
uniform float dash_gap = 0.05; // Gap between dashes in UV space
uniform float speed = 1.0; // Animation speed
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Border color

// Streak properties
uniform float streak_intensity : hint_range(0.0, 2.0) = 0.8;
uniform float streak_width : hint_range(0.0, 0.5) = 0.2;
uniform float streak_speed : hint_range(0.0, 5.0) = 2.0;
uniform int streak_count : hint_range(1, 10) = 3;
uniform vec4 streak_color : source_color = vec4(0.5, 0.8, 1.0, 1.0); // Blue-ish streaks

void fragment() {
    vec2 uv = UV;
    vec2 center = vec2(0.5, 0.5);
    vec2 size = vec2(0.5, 0.5); // Rectangle half-size (width, height) in UV space

    // Calculate signed distance to a rounded rectangle
    vec2 d = abs(uv - center) - size + vec2(corner_radius);
    float dist = min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - corner_radius;

    // Calculate perimeter position for continuous dashing
    vec2 pos = uv - center;
    float t = 0.0;
    float perimeter = 2.0 * (size.x + size.y); // Approximate perimeter (adjusted for rounding)

    // Determine the segment and compute normalized perimeter position
    vec2 abs_pos = abs(pos);
    float u = 0.0;
    if (abs_pos.x > abs_pos.y) {
        if (pos.x > 0.0) {
            // Right edge
            u = (pos.y + size.y) + size.x;
        } else {
            // Left edge
            u = (size.y - pos.y) + 3.0 * size.x;
        }
    } else {
        if (pos.y > 0.0) {
            // Top edge
            u = (size.x - pos.x);
        } else {
            // Bottom edge
            u = (pos.x + size.x) + 2.0 * size.x;
        }
    }

    // Adjust perimeter for rounded corners (approximation)
    perimeter += 2.0 * 3.141592 * corner_radius * 0.5; // Add corner arc lengths
    u = fract(u / perimeter + TIME * speed);

    // Dash pattern
    float dash_cycle = dash_length + dash_gap;
    float pattern_pos = mod(u * perimeter, dash_cycle);

    // Apply blur to all edges of the border
    float edge_alpha = smoothstep(border_width + blur, border_width - blur, abs(dist));

    // Ensure the border is fully blurred across its width
    float border_mask = step(abs(dist), border_width + blur);

    // --- BLURRY COLOR STREAKS IN THE MIDDLE ---
    vec4 streak_result = vec4(0.0);
    
    for (int i = 0; i < streak_count; i++) {
        // Create multiple moving streaks
        float streak_offset = float(i) / float(streak_count);
        float streak_time = TIME * streak_speed + streak_offset * 3.141592;
        
        // Create horizontal streaks that move vertically
        float streak_pos = sin(streak_time) * 0.4 + 0.5; // Oscillate around center
        float streak_dist = abs(uv.y - streak_pos);
        
        // Add some horizontal movement variation
        float horizontal_wave = sin(uv.x * 10.0 + streak_time * 2.0) * 0.1;
        streak_dist = abs(uv.y - (streak_pos + horizontal_wave));
        
        // Create blurry streak with soft edges
        float streak_alpha = 1.0 - smoothstep(0.0, streak_width, streak_dist);
        
        // Add pulsing intensity
        float pulse = (sin(streak_time * 1.5) + 1.0) * 0.5;
        streak_alpha *= streak_intensity * (0.7 + 0.3 * pulse);
        
        // Color variation
        vec4 current_streak_color = streak_color;
        current_streak_color.rgb *= (0.8 + 0.2 * sin(streak_time + float(i)));
        
        streak_result += current_streak_color * streak_alpha;
    }
    
    // Clamp streak intensity
    streak_result = min(streak_result, 1.0);
    
    // Combine border and streaks
    vec4 final_color = vec4(0.0);
    float final_alpha = 0.0;
    
    // Apply border
    if (pattern_pos < dash_length && border_mask > 0.0) {
        final_color = border_color;
        final_alpha = border_color.a * edge_alpha;
    }
    
    // Add streaks (only in the interior, not on the border)
    if (abs(dist) > border_width) {
        final_color = mix(final_color, streak_result, streak_result.a);
        final_alpha = max(final_alpha, streak_result.a);
    }
    
    COLOR.rgb = final_color.rgb;
    COLOR.a = final_alpha;
}