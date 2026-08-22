shader_type canvas_item;

void vertex() {
	float vtxmul = cos(TIME * 0.1);
	vtxmul = pow(vtxmul, 4.0);
	VERTEX.y += sin(TIME + VERTEX.x * 5184.0 / cos(VERTEX.y * 43.0)) * 14.0 * vtxmul;
	VERTEX.x += sin(TIME) * 10.0;
}

void fragment() {
	vec4 trues = texture(TEXTURE, UV);
	vec4 sample = vec4(vec3(0.0), 0.0);
	float dist = 0.005;

	vec4 sampler = texture(TEXTURE, vec2(UV.x - sin(TIME * 2.0) * dist * 4.0, UV.y));
	vec4 sampleg = texture(TEXTURE, vec2(UV.x, UV.y + cos(TIME) * dist));
	vec4 sampleb = texture(TEXTURE, vec2(UV.x - sin(TIME) * dist, UV.y - cos(TIME) * dist));
	if (sampler.a > 0.0) {
		sample.r += sampler.r * 0.4;
		sample.a += sampler.a * 0.33;
	}
	if (sampleg.a > 0.0) {
		sample.g += sampleg.r * 0.6;
		sample.a += sampleg.a * 0.33;
	}
	if (sampleb.a > 0.0) {
		sample.b += sampleb.r * 0.8;
		sample.a += sampleb.a * 0.33;
	}

	COLOR = sample;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
