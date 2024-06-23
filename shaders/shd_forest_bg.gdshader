shader_type canvas_item;



const float height = 5.0;


//void vertex() {
	//vec2 pos = VERTEX;
	//VERTEX.y += sin(TIME + pos.x) * height;
	//VERTEX.x += sin(TIME + pos.y) * height;
//}

void fragment() {
	vec2 uv = UV;
	uv.y += sin(TIME + uv.x * 2.5) * 0.04;
	uv.x += cos(TIME + UV.y * 1.5) * 0.08;
	vec4 color = texture(TEXTURE, uv);
	vec4 color2 = color;
	color2.r = smoothstep(color2.g, color2.b, sin(TIME - uv.y * uv.x) * 0.5 + 0.2);
	color2.g = smoothstep(color2.b, color2.g, cos(TIME + uv.y / uv.x) * 0.5 + 0.2);
	vec3 color3 = vec3(
		smoothstep(color.r, color2.r, 1.0),
		smoothstep(color.g, color2.g, 0.01),
		smoothstep(color.b, color2.b, 0.01)
	);
	vec3 mixed = vec3(
		mix(color.r, color3.r, 0.6 * sin(TIME + sin(uv.x / uv.y) * 100.0)),
		mix(color.g, color3.g, 0.2 * cos(TIME)),
		mix(color.b, color3.b, 0.4 * sin(TIME + uv.y))
	);
	mixed.rgb *= 0.02 * (sin(TIME + uv.x * 11.0) + cos(TIME + uv.y * 12.0) + 8.0);
	COLOR.rgb = mixed;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
