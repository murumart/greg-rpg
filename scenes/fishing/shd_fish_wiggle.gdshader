shader_type canvas_item;

uniform float speed = 2.0;

varying vec4 modulate;

void vertex() {
	//VERTEX.y += sin((TIME + VERTEX.x * speed) * speed) * speed / 2.0;
	modulate = COLOR;
}

void fragment() {
	vec2 uv = UV;
	uv.y += sin(uv.x * 3.0 + TIME * speed) * 0.05;
	COLOR = modulate * texture(TEXTURE, uv);
}
