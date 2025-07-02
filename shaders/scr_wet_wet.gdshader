shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	vec2 uv = SCREEN_UV;
	uv.y += sin(uv.x + TIME * 2.0) * 0.009;
	uv.x += sin(uv.y + TIME * 2.0) * 0.009;
	vec4 sample1 = textureLod(screen_texture, uv, 0.0);
	float change_rate = cos(TIME * 0.1) * 0.1 * sin(TIME * 0.15) * 0.2;
	uv.y += sin(uv.x * 40.0 + TIME + change_rate * uv.y) * 0.02;
	uv.x += sin(uv.y * 25.0 + TIME * change_rate + uv.y) * 0.01;
	vec4 col = textureLod(screen_texture, uv, 0.0);
	col.r -= sample1.r;
	col.r *= 0.25 + sin(uv.y * 10.0) + 1.0;
	col.r = max(0.0, col.r * 0.5);
	col.g *= sin(TIME + uv.x) * 0.5 + 0.5;
	col.r *= cos(TIME - 20.0 + (1.0 - uv.x)) * 0.5 + 0.5;
	col.b = max(max(col.g, col.r), sample1.b);
    COLOR = col;
}
