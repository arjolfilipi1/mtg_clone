shader_type canvas_item;

// --- Glow tunables ---
uniform float pulse_speed : hint_range(0.5, 5.0) = 0.5;
uniform float glow_radius : hint_range(1.0, 20.0) = 20.0;
uniform float glow_intensity : hint_range(0.5, 5.0) = 4.5;
uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 1.0, 1.0);

// --- Expanding pulse ring tunables ---
uniform float ring_speed : hint_range(0.5, 5.0) = 4.2;
uniform float ring_thickness : hint_range(0.01, 0.3) = 0.3;
uniform float ring_intensity : hint_range(0.5, 5.0) = 4.8;

void fragment() {
    vec4 base = texture(TEXTURE, UV);
    vec2 texel = TEXTURE_PIXEL_SIZE;

    // -------------------------------------------------------
    // 1. FRAME GLOW — spread alpha from opaque pixels outward
    // -------------------------------------------------------
    float pulse = 0.55 + 0.45 * sin(TIME * pulse_speed * 3.14159);

    float alpha_spread = 0.0;
    int samples = 12;
    for (int i = 1; i <= samples; i++) {
        float r = float(i) / float(samples) * glow_radius;
        alpha_spread += texture(TEXTURE, UV + vec2( r,  0.0) * texel).a;
        alpha_spread += texture(TEXTURE, UV + vec2(-r,  0.0) * texel).a;
        alpha_spread += texture(TEXTURE, UV + vec2( 0.0,  r) * texel).a;
        alpha_spread += texture(TEXTURE, UV + vec2( 0.0, -r) * texel).a;
        alpha_spread += texture(TEXTURE, UV + vec2( r,  r) * texel * 0.707).a;
        alpha_spread += texture(TEXTURE, UV + vec2(-r,  r) * texel * 0.707).a;
        alpha_spread += texture(TEXTURE, UV + vec2( r, -r) * texel * 0.707).a;
        alpha_spread += texture(TEXTURE, UV + vec2(-r, -r) * texel * 0.707).a;
    }
    alpha_spread = clamp(alpha_spread / float(samples * 8), 0.0, 1.0);
    float glow_alpha = pow(alpha_spread, 1.8) * pulse * glow_intensity;

    // Tint visible frame pixels toward glow_color
    vec4 tinted = base;
    if (base.a > 0.01) {
        tinted.rgb = mix(base.rgb, glow_color.rgb, pulse * 0.75);
    }

    vec4 glow_layer = vec4(glow_color.rgb, glow_alpha * glow_color.a);
    vec4 frame_result = mix(glow_layer, tinted, base.a);

    // -------------------------------------------------------
    // 2. EXPANDING PULSE RING — samples the card shape
    // -------------------------------------------------------
    // Ring progress: 0.0 = just born at center, 1.0 = fully expanded
    float ring_t = fract(TIME * ring_speed * 0.4);

    // For each fragment, check if any nearby opaque pixel exists at
    // a scaled-down version of the shape (approximating the ring front).
    // We do this by checking the distance from UV to card center
    // and comparing against the ring's current expansion radius.

    // Distance from UV centre (0..~0.7 at corners for a unit square)
    vec2 centered = UV - vec2(0.5);
    float dist = length(centered);

    // The ring expands from 0 to ~0.75 (corner distance of a 1:1 quad)
    float max_dist = 0.75;
    float ring_front = ring_t * max_dist;

    // How far this pixel is from the ring front
    float ring_dist = abs(dist - ring_front);

    // Soft ring band
    float ring_band = 1.0 - smoothstep(0.0, ring_thickness, ring_dist);

    // Fade the ring as it expands (born bright, dies at edge)
    float ring_fade = 1.0 - smoothstep(0.0, 1.0, ring_t);
    // Also fade in sharply at birth so it doesn't pop
    float ring_fadein = smoothstep(0.0, 0.08, ring_t);

    // Only render the ring where there is (or was) card shape —
    // sample the texture at a contracted UV toward center to get shape mask
    // Scale UV inward proportionally to ring progress to match shape
    float scale = mix(0.01, 1.0, ring_t);
    vec2 sampled_uv = (UV - 0.5) / scale + 0.5;
    float shape_mask = 0.0;
    if (sampled_uv.x >= 0.0 && sampled_uv.x <= 1.0 &&
        sampled_uv.y >= 0.0 && sampled_uv.y <= 1.0) {
        shape_mask = texture(TEXTURE, sampled_uv).a;
    }

    float ring_alpha = ring_band * ring_fade * ring_fadein * ring_intensity * shape_mask;
    vec4 ring_layer = vec4(glow_color.rgb, clamp(ring_alpha, 0.0, 1.0));

    // -------------------------------------------------------
    // 3. COMPOSITE — ring behind glow, glow behind frame
    // -------------------------------------------------------
    // Additive blend ring onto glow
    vec4 combined = frame_result;
    combined.rgb += ring_layer.rgb * ring_layer.a;
    combined.a = max(frame_result.a, ring_layer.a);

    COLOR = combined;
}