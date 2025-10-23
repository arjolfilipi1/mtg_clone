shader_type canvas_item;
uniform bool destroy = false;
uniform float grayscale_amount : hint_range(0.0, 1.0) = 0.0;
uniform float alpha_override : hint_range(0.0, 1.0) = 1.0;
uniform float corner_scale: hint_range(0., 1.) = 0.15;
uniform float progress = 0.0;
uniform float noiseForce = 0.2;
uniform sampler2D noiseTexture;
uniform vec4 burnColor: source_color;
uniform float borderWidth;
uniform float direction = 180.0f;
vec2 degreesToPerpendicular(){
	return vec2(cos(radians((direction))), -sin(radians(direction)));
}

bool isOut(float x, float y) {
    return pow(x, 2.) + pow(y, 2.) > pow(corner_scale * .5, 2.);
}
void fragment() {
	float s = corner_scale * .5;

    if (
        (UV.x < s      && UV.y < s      && isOut(UV.x - s,      UV.y - s)) ||
        (UV.x < s      && UV.y > 1. - s && isOut(UV.x - s,      UV.y - 1. + s)) ||
        (UV.x > 1. - s && UV.y < s      && isOut(UV.x - 1. + s, UV.y - s)) ||
        (UV.x > 1. - s && UV.y > 1. - s && isOut(UV.x - 1. + s, UV.y - 1. + s))
    ) {
        COLOR.a = 0.;
    }else{
    vec4 tex_color = texture(TEXTURE, UV);
	if (destroy ){
		vec2 normUV = UV * 2.0 - 1.0;
	COLOR.rgb = mix(COLOR.rgb, burnColor.rgb, float(dot(normUV, degreesToPerpendicular()) + (texture(noiseTexture, UV).r * noiseForce) < (progress + borderWidth)));
	if(!(dot(normUV, degreesToPerpendicular()) + (texture(noiseTexture, UV).r * noiseForce) > progress)){
		COLOR.a = 0.0;
	}
	} 
	else {
    float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
    tex_color.rgb = mix(tex_color.rgb, vec3(gray), grayscale_amount);
    tex_color.a *= alpha_override;
	COLOR = tex_color;
}
    
}}