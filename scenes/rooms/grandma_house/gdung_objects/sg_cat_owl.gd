extends OverworldCharacter

@onready var sprite: AnimatedSprite2D = $Sprite


func scary() -> void:
	sprite.play(&"default")
	await SND.play_sound(preload("res://sounds/owl.ogg")).finished
