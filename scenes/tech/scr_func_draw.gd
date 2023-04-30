@tool
extends Node2D

@export var funk : Callable = f
@export var range := 50
@export var func_scale := Vector2(2, 2)
@export var values : Array[float] = []
@export var redraw: bool = false:
	set(to):
		queue_redraw()


func f(x: int) -> float:
	return x


func _draw() -> void:
	var multx := func_scale.x
	var multy := func_scale.y
	if not values.size() > 0:
		for i in range:
			draw_line(Vector2((i + 1) * multx, (-f(i)) * multy + 120), Vector2((i + 2) * multx, (-f(mini(i + 1, range - 1))) * multy + 119), Color.BLACK, 1.0)
		return
	
	for i in values:
			draw_line(Vector2((i + 1) * multx, (-values[i]) * multy + 120), Vector2((i + 2) * multx, (-values[mini(i + 1, range - 1)]) * multy + 119), Color.BLACK, 1.0)
	
