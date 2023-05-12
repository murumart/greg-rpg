extends Node2D

var transing := false


func _input(event: InputEvent) -> void:
	if transing: return
	if event.is_action_pressed("ui_accept"):
		transing = true
		LTS.level_transition("res://scenes/biking/scn_biking_game.tscn")
