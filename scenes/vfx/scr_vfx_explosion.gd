extends Node2D


func init(options := {}):
	if options.get("silent", false):
		return
	SND.play_sound(
		[
			preload("res://sounds/explosion/explosion_1.ogg"),
			preload("res://sounds/explosion/explosion_2.ogg"),
			preload("res://sounds/explosion/explosion_3.ogg"),
		].pick_random()
	)

