// rote this myslef coptright murumart 20204
// and godot docs for the part i didnt write

shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest; // canvgroup
uniform sampler2D noise_texture: filter_nearest, repeat_enable;
uniform float iridescence_reducer = 0.85f;
uniform float iridescence_reducer_multiplier = 1.0f;

const float noise_time_scale = 0.2f;
const float uv_scale = 0.5f;
const float cyamag_diff = 0.75f;

void fragment() {
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0); // canvgroup

	//COLOR = vec4(COLOR.r, (sin(TIME) + 1.0f) * 0.5f, COLOR.b, COLOR.a);
	float diff = (sin(TIME * 0.05f) + 1.0f) * cyamag_diff;
	vec2 noise_color = vec2(
			texture(noise_texture,
					vec2(((UV.x * uv_scale) - sin(TIME * noise_time_scale)),
					(UV.y * uv_scale) - (TIME * noise_time_scale))
			).r,
			texture(noise_texture,
					vec2(((UV.x * uv_scale) - sin(TIME * noise_time_scale)) - diff,
					(UV.y * uv_scale) - (TIME * noise_time_scale)) - diff
			).r
	) * (1.0f - iridescence_reducer * iridescence_reducer_multiplier);
	COLOR = vec4(COLOR.r + noise_color.x, COLOR.g + noise_color.x, COLOR.b + noise_color.y, COLOR.a);
	COLOR *= c; // canvgroup
}
