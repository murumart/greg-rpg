shader_type canvas_item;

uniform sampler2D noise_texture: filter_nearest, repeat_enable;

void vertex() {
	vec2 vertex = VERTEX;
	float super_offset = cos(TIME * 0.01 + VERTEX.x * 0.01 + VERTEX.y * 0.02) * 16.0;
	vertex.x += sin(vertex.y + TIME) * 3.0 + super_offset;
	vertex.y += cos(vertex.x + TIME) * 3.0 - sin(super_offset) * 16.0;
	VERTEX = vertex;
}

void fragment() {
	float noise = texture(noise_texture, vec2(
		sin(TIME * 0.02 + SCREEN_UV.x),
		cos(TIME * 0.02 + SCREEN_UV.y))).r;
	vec2 uv = UV;
	uv.x += sin(uv.y * 20.0 + TIME * 0.3) * 0.9;
	uv.y += cos(uv.x * 20.0 + TIME * 0.4) * 0.4;

	COLOR = texture(TEXTURE, uv);
	COLOR.r = uv.x * 2.0;
	COLOR.g = uv.y * uv.x * cos(uv.x + TIME * 0.2);
	COLOR.a = uv.y * sin(TIME * cos(TIME * 0.005) + uv.x * 2.0);
	COLOR.a *= noise;
	COLOR.r *= 2.0;
	COLOR.b *= 3.0;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
