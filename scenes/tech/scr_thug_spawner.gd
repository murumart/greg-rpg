extends Node2D

const MAX_THUGS := 8
const THUG_SCENE := preload("res://scenes/characters/overworld/scn_thug_overworld.tscn")

@export var player : PlayerOverworld
@export var wait_time := 1.0

@onready var timer := $Timer


func _on_timer_timeout() -> void:
	timer.start(wait_time)
	var thug_amount : int = 0
	if thug_amount < MAX_THUGS and randf() <= 0.25:
		var thug := THUG_SCENE.instantiate()
		if player:
			thug.chase_target = player
		add_child(thug)
