class_name CigaretteOverworld extends Area2D

const SCENE := preload("res://scenes/decor/scn_cigarette_overworld.tscn")
@onready var timer: Timer = $Timer


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerOverworld:
		DAT.grant_item("cigarette")
		delete()


func start_timer(time: float) -> void:
	timer.start(time)
	timer.timeout.connect(delete)


func save_key() -> String:
	return "cigarettes_in_" + LTS.get_current_scene().name.to_snake_case()


func _save_me() -> void:
	var cigarette_positions := DAT.get_data(save_key(), {}) as Dictionary
	cigarette_positions[global_position] = {
		"rotation": rotation, "time": timer.time_left}
	DAT.set_data(save_key(), cigarette_positions)


func tumble() -> void:
	start_timer(randf_range(6, 9))
	var tw := create_tween()
	tw.tween_property(self, "global_position", 
			global_position + Vector2(randf_range(-2, 2), randf_range(-2, 2)),
			1.0)
	tw.parallel().tween_property(self, "rotation", TAU * randf_range(-8, 8), 1.0)


func delete() -> void:
	var cigarette_positions := DAT.get_data(save_key(), {}) as Dictionary
	cigarette_positions.erase(global_position)
	DAT.set_data(save_key(), cigarette_positions)
	queue_free()

