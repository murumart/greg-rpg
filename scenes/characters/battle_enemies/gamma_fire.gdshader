shader_type canvas_item;
render_mode blend_add;

void vertex() {
	VERTEX.y += sin(VERTEX.x + TIME * 3.0) * 1.0;
}

void fragment() {
	vec2 uv = UV;
	uv.y -= sin(uv.x * 20.0 - TIME * 10.0) * 0.05;
	uv.x -= cos(UV.y * 10.0) * 0.01;
	vec4 col1 = texture(TEXTURE, uv);
	uv.y += cos(UV.x * 10.0 + TIME * 20.0) * 0.04;
	uv.x += sin(UV.y * 20.0 + TIME * 10.0) * 0.02;
	vec4 col2 = texture(TEXTURE, uv);
	COLOR = col1 * 0.7 + col2 * 0.4;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
