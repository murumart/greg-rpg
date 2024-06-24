shader_type canvas_item;

uniform float speed = 2.0;

void vertex() {
	//VERTEX.y += sin((TIME + VERTEX.x * speed) * speed) * speed / 2.0;
}

void fragment() {
	vec2 uv = UV;
	uv.y += sin(uv.x * 3.0 + TIME * speed) * 0.05;
	COLOR = texture(TEXTURE, uv);
}
