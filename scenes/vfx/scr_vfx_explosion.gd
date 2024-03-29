extends Node2D

var silent := false


func init(options := {}):
	silent = options.get("silent", false)


func _ready() -> void:
	if silent: return
	SND.play_sound(
		[
			preload("res://sounds/explosion/explosion_1.ogg"),
			preload("res://sounds/explosion/explosion_2.ogg"),
			preload("res://sounds/explosion/explosion_3.ogg"),
		].pick_random()
	)
