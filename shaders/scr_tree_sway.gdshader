shader_type canvas_item;

global uniform float wind_strength;

// SimplexNoise2D

vec3 _permute_simplex2_n0ise(vec3 x) {
	return ((x*34.0)+1.0)*x-floor(((x*34.0)+1.0)*x*(1.0/289.0))*289.0;
}

float simplex2dN0iseFunc(vec2 v) {
	vec4 C = vec4(0.211324865405187,
				0.366025403784439,
				-0.577350269189626,
				0.024390243902439);

	vec2 i  = floor(v + dot(v, C.yy) );
	vec2 x0 = v -   i + dot(i, C.xx);

	vec2 i1;
	i1 = (x0.x > x0.y) ? vec2(1.0, 0.0): vec2(0.0, 1.0);
	vec4 x12 = vec4(x0.xy, x0.xy) + C.xxzz;
	x12.xy -= i1;

	i = i - floor(i * (1.0 / 289.0)) * 289.0;
	vec3 p = _permute_simplex2_n0ise(_permute_simplex2_n0ise(i.y + vec3(0.0, i1.y, 1.0 )) + i.x + vec3(0.0, i1.x, 1.0));

	vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), vec3(0.0));
	m = m * m;
	m = m * m;

	vec3 x = 2.0 * fract(p * C.www) - 1.0;
	vec3 h = abs(x) - 0.5;
	vec3 ox = floor(x + 0.5);
	vec3 a0 = x - ox;

	m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);

	vec3 g;
	g.x  = a0.x  * x0.x  + h.x  * x0.y;
	g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	return 130.0 * dot(m, g);
}

// InverseColor

vec3 inverseC0l0rFunc(vec3 _c0l0r_to_inverse, float _inverse_c0l0r_intensity){
	return mix(_c0l0r_to_inverse.rgb, 1.0 - _c0l0r_to_inverse.rgb, _inverse_c0l0r_intensity);
}

varying vec4 vtx_color;

void vertex() {
	vtx_color = COLOR;
}

void fragment() {
	float scaled_time = sin(0.25000 * TIME);

// SimplexNoise2D:9
	float get_noise = simplex2dN0iseFunc(UV + vec2(scaled_time));

// InverseColor:16
	vec3 invcol = inverseC0l0rFunc(vec3(UV.y), 1.00000);

// ScalarOp:14
	float dotreslt = wind_strength * dot(invcol, vec3(0.33333, 0.333333, 0.333333));

// VectorMix:11
	vec2 readuv = mix(UV, UV * vec2(get_noise), vec2(dotreslt));

// Texture:2
	vec4 _tex_read = texture(TEXTURE, readuv);
	vec3 texture_colours = _tex_read.rgb;

// Output:0
	COLOR.rgb = texture_colours * vtx_color.rgb;
	COLOR.a = _tex_read.a * vtx_color.a;

}

void light() {
// Output:0

}