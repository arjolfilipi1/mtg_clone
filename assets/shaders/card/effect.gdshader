shader_type canvas_item;

uniform float speed = 2.0;
uniform float transparency_threshold = 0.5;
uniform bool activated = false;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

vec3 palette( float t ) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.263,0.416,0.557);

    return a + b*(cos( 6.28318*(c*t+d) ) );
}

void fragment() {
    // Use TEXTURE_PIXEL_SIZE instead of SCREEN_PIXEL_SIZE
    vec2 object_size = 1.0 / TEXTURE_PIXEL_SIZE;
    
    // Use UV coordinates instead of FRAGCOORD to make it object-relative
    vec2 uv = (UV * 2.0 - 1.0) * object_size / object_size.y;
    vec2 uv0 = uv;
    vec3 finalColor = vec3(0.0);
    
    // Calculate progress - only animate when activated
    float animation_time = 0.0;
    if (activated) {
        animation_time = progress * speed;
    }
    
    for (float i = 0.0; i < 4.0; i++) {
        uv = fract(uv * 1.5) - 0.5;

        float d = length(uv) * exp(-length(uv0));

        vec3 col = palette(length(uv0) + i*.4 + animation_time*.4);

        d = sin(d*8. + animation_time)/8.;
        d = abs(d);

        d = pow(0.01 / d, 1.2);

        finalColor += col * d;
    }
    
    // Oval-shaped fadeout using elliptical distance
    vec2 centered_uv = (UV - 0.5) * 2.0;
    // Create oval shape by scaling X differently than Y
    float oval_mask = 1.0 - length(centered_uv * vec2(1.2, 1.0));
    oval_mask = smoothstep(0.0, 0.8, oval_mask); // Smooth edges
    
    // Apply transparency threshold and oval mask
    float brightness = length(finalColor);
    float alpha = step(transparency_threshold, brightness) * oval_mask;
    
    // Fade out based on progress (optional - makes effect disappear after completion)
    if (activated && progress >= 0.95) {
        alpha *= 1.0 - ((progress - 0.95) * 20.0);
    }
        
    COLOR = vec4(finalColor, alpha);
}