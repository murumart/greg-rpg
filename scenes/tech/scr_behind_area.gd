extends Area2D

# changes alpha of selected node when something enters this area
# used to make trees transparent when going behind them

@export var affected_node: Node2D
@export_group("Technical")
@export var change_time := 0.25
@export var final_alpha := 0.5
@export var default_alpha := 1.0


func _ready() -> void:
	affected_node.modulate.a = default_alpha


func _on_body_entered(_body: Node2D) -> void:
	var tw := create_tween()
	tw.tween_property(affected_node, "modulate:a", final_alpha, change_time)


func _on_body_exited(_body: Node2D) -> void:
	var tw := create_tween()
	tw.tween_property(affected_node, "modulate:a", default_alpha, change_time)
