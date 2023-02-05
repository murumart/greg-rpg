extends Area2D

@export var affected_node : Node2D
@export_group("Technical")
@export var change_time := 0.25
@export var final_alpha := 0.5


func _on_body_entered(_body: Node2D) -> void:
	var tw := create_tween()
	tw.tween_property(affected_node, "modulate:a", final_alpha, change_time)


func _on_body_exited(_body: Node2D) -> void:
	var tw := create_tween()
	tw.tween_property(affected_node, "modulate:a", 1.0, change_time)
