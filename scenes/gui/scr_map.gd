extends Sprite2D


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel") or event.is_action_pressed("ui_accept"):
		DAT.free_player("map")
		queue_free()
