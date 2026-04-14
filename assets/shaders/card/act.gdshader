shader_type canvas_item;

// --- Tunables ---
uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform float glow_radius : hint_range(1.0, 100.0) = 80.0;
uniform float glow_intensity : hint_range(0.5, 5.0) = 2.5;
uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.0, 1.0); // YGO gold-yellow
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec4 base = texture(TEXTURE, UV);

    // --- Pulse factor (smooth sine wave, never fully off) ---
    float pulse = 0.55 + 0.45 * sin(TIME * pulse_speed * 3.14159);

    // --- Spread glow by sampling neighbours in a cross pattern ---
    vec2 texel = TEXTURE_PIXEL_SIZE;
    float alpha_spread = 0.0;
    int samples = 12;

    for (int i = 1; i <= samples; i++) {
        float r = float(i) / float(samples) * glow_radius;
        // 8-directional sampling for a round halo
        alpha_spread += texture(TEXTURE, UV + vec2( r,  0.0) * texel).a;
        alpha_spread += texture(TEXTURE, UV + vec2(-r,  0.0) * texel).a;
        alpha_spread += texture(TEXTURE, UV + vec2( 0.0,  r) * texel).a;
        alpha_spread += texture(TEXTURE, UV + vec2( 0.0, -r) * texel).a;
        alpha_spread += texture(TEXTURE, UV + vec2( r,  r) * texel * 0.707).a;
        alpha_spread += texture(TEXTURE, UV + vec2(-r,  r) * texel * 0.707).a;
        alpha_spread += texture(TEXTURE, UV + vec2( r, -r) * texel * 0.707).a;
        alpha_spread += texture(TEXTURE, UV + vec2(-r, -r) * texel * 0.707).a;
    }

    // Normalise and shape the glow falloff
    alpha_spread = clamp(alpha_spread / float(samples * 8), 0.0, 1.0);
    // Smooth falloff so it fades toward the outer edge
    float glow_alpha = pow(alpha_spread, 1.8) * pulse * glow_intensity;

    // --- Tint the original black frame pixels yellow ---
    vec4 tinted = base;
    if (base.a > 0.01) {
        // Blend the frame toward glow_color based on pulse strength
        tinted.rgb = mix(base.rgb, glow_color.rgb, pulse * 0.75);
        tinted.a = base.a;
    }

    // --- Composite: glow halo behind original pixels ---
    vec4 glow_layer = vec4(glow_color.rgb, glow_alpha * glow_color.a);

    // If original pixel is opaque, show tinted frame; else show glow halo
    COLOR = mix(glow_layer, tinted, base.a);
}
