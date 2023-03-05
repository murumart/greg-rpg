extends Node2D


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		LTS.level_transition("res://scenes/biking/scn_biking_game.tscn")
