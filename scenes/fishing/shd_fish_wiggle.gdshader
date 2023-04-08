shader_type canvas_item;

uniform float speed = 2.0;

void vertex() {
	VERTEX.y += sin((TIME + VERTEX.x * speed) * speed) * speed / 2.0;
}
