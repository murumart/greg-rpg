extends Node2D

var zoom := 1.0


func _ready() -> void:
	set_physics_process(false)


func _on_inside_area_body_entered(body: PlayerOverworld) -> void:
	var tw := create_tween()
	var camera := body.find_child("Camera") as Camera2D
	tw.tween_property(camera, "zoom", Vector2(2, 2), 1)
	set_physics_process(true)


func _on_inside_area_body_exited(body: PlayerOverworld) -> void:
	var tw := create_tween()
	var camera := body.find_child("Camera") as Camera2D
	tw.tween_property(camera, "zoom", Vector2(1, 1), 1)
	set_physics_process(false)
	zoom = 1.0


func _physics_process(delta: float) -> void:
	zoom = move_toward(zoom, 2.0, delta)
	if zoom >= 2.0:
		set_physics_process(false)




