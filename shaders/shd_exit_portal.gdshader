shader_type canvas_item;

uniform float modulate_a = 1.0;

// https://forum.godotengine.org/t/simple-texture-rotation-shader/24198/2
vec2 rotateUV(vec2 uv, vec2 pivot, float rotation) {
    float sine = sin(rotation);
    float cosine = cos(rotation);

    uv -= pivot;
    uv.x = uv.x * cosine - uv.y * sine;
    uv.y = uv.x * sine + uv.y * cosine;
    uv += pivot;

    return uv;
}

void fragment() {
	vec2 uv = UV;
	uv.x += cos(TIME + sin(UV.y * 0.8) * 50.0 *
			abs(cos(TIME + uv.x * sin(uv.y * -29.0 + cos(uv.x * 2.0) * 12.0)))) * 0.03;
	float red_sample = COLOR.r;
	uv.y += sin(TIME - cos(UV.x * sin(-UV.y * 24.0)) * 50.0) * 0.03;
	float green_sample = texture(TEXTURE, uv).g;
	vec4 color2 = texture(TEXTURE, uv);
	uv = rotateUV(uv, vec2(0.33), sin(uv.x + TIME * 0.002));
	color2.r = mix(green_sample, red_sample * cos(uv.y + TIME * 0.2),
			sin(TIME * (-uv.x * 0.01 + uv.y * 0.006)) * 0.5 + 1.0);
	uv = rotateUV(uv, vec2(0.87), sin(uv.y * cos(uv.x + TIME * 0.2) + TIME * 3.0));
	color2.g = mix(red_sample, green_sample, sin(uv.x - cos(uv.y - TIME) * TIME * 0.002));
	uv.x -= cos(uv.y - TIME);
	uv.y += sin(uv.x - TIME);
	color2.r = mix(texture(TEXTURE, uv).r, color2.r, sin(TIME + uv.y * 0.02) * 0.5 + 1.0 - COLOR.a);
	color2.g = mix(texture(TEXTURE, uv).g, color2.g, sin(TIME - cos(uv.x)) * 0.5 + 1.0);
	color2.b = mix(texture(TEXTURE, uv).b, color2.b, sin(TIME * 28.0 * COLOR.a) * 0.5 + 1.0);
	COLOR = color2;
	COLOR.r *= 2.0 + sin(TIME);
	COLOR.g *= 2.0;
	COLOR.b *= (3.0 + cos(UV.x * 12.0 * uv.y + TIME));
	COLOR.a *= modulate_a;
}
