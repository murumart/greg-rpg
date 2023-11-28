extends Area2D

# that's how mafia works

@onready var mafia_1_sprite: AnimatedSprite2D = $"../../Decorations/Mafia/AnimatedSprite2D"
@onready var mafia_2_sprite: AnimatedSprite2D = $"../../Decorations/Mafia2/AnimatedSprite2D"
@onready var greg: CharacterBody2D = $"../../Greg"

func _ready() -> void:
	SOL.dialogue("mafia_mumbles_1")


func _area_entered() -> void:
	DAT.capture_player("mafia")
	SOL.dialogue("mafia_interrupt")
	var anim := "walk_right" if mafia_1_sprite.global_position.x - greg.global_position.x < -1 else "walk_left"
	mafia_1_sprite.play(anim)
	mafia_2_sprite.play(anim)
