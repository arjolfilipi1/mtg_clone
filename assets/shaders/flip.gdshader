shader_type canvas_item;

uniform float scale_x = 0.1;
uniform float edge_threshold = 0.09;
uniform vec4 edge_color : source_color = vec4(0.1, 0.1, 0.1, 1.0);

void fragment() {
    if (abs(scale_x) < edge_threshold) {
        // Show edge color when the object is narrow
        COLOR = edge_color;
    } else {
        // Default texture color
        COLOR = texture(TEXTURE, UV);
    }
}