extends Control


@export var intensity := 1.0
@export var speed := 1.0
@export var idiff := 0.1

var _d := 0.0


func _process(delta: float) -> void:
	for i in get_child_count():
		var c: Control = get_child(i)
		c.offset_transform_position.x += sin(_d * speed + i * idiff) * delta * intensity * (1.0 - (7 - i) * 0.2)
		c.offset_transform_position.y += cos(_d * speed + i * idiff) * delta * intensity
		c.offset_transform_position.y += sin(c.position.x + _d * speed) * delta * intensity
	_d += delta
