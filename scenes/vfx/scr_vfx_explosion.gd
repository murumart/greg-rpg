extends Node2D

func _ready() -> void:
	SND.play_sound(
		[
			preload("res://sounds/explosion/snd_explosion_1.ogg"),
			preload("res://sounds/explosion/snd_explosion_2.ogg"),
			preload("res://sounds/explosion/snd_explosion_3.ogg"),
		].pick_random()
	)
