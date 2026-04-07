shader_type canvas_item;

uniform float zoom : hint_range(0.0, 1.0, 0.1);
uniform float white : hint_range(0.0, 1.0, 0.1);
uniform float gray : hint_range(0.0, 1.0, 0.1);
uniform float flower : hint_range(0.0, 1.0, 0.1);

uniform sampler2D screen : hint_screen_texture, filter_nearest;

float superRad(
    float phi,
    float a,
    float b,
    float m,
    float n1,
    float n2,
    float n3
) {
    float leftside = pow(abs(cos((m * phi) / 4.0) / a), n2);
    float rightside = pow(abs(sin((m * phi) / 4.0) / b), n3);
    return pow(leftside + rightside, -1.0 / n1);
}

// vec2(phi, r)
vec2 polar2Cart(vec2 pr) {
    return vec2(pr.y * cos(pr.x), pr.y * sin(pr.x));
}

// vec2(phi, r)
vec2 cart2Polar(float x, float y) {
    return vec2(atan(x, y), sqrt(x*x + y*y));
}

void fragment() {
	vec2 zoomv = vec2(zoom);
	vec2 uv = (SCREEN_UV - vec2(0.5)) * zoomv + vec2(0.5);
	vec4 sample = texture(screen, uv);
	
	vec4 color = sample;
	color = mix(color, vec4(1.0), white);
	
	vec4 grey;
	{
		float max1 = max(color.r, color.g);
		float max2 = max(max1, color.b);
		grey = vec4(max2, max2, max2, 1.0);
	}
	
	color = mix(color, grey, gray);
	
	vec2 polar = cart2Polar(UV.x - 0.5, UV.y -0.5);
	
	float nflower = 1.0 - flower;
	
	float superr = superRad(
		polar.x + TIME * 4.0,
		0.4,
		0.1,
		14.0,
		48.0 * nflower + 8.0,
		12.0 + nflower,
		8.0
	);
	
	if (polar.y > superr) {
		color = vec4(1.0);
	}
	COLOR = color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
