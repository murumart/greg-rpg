extends Node2D

# overworld npc spawner node

@export var spawn_enemy : PackedScene
@export var max_enemies := 8
var enemy_amount := 0

@export var player : PlayerOverworld
@export var active_range := Vector2i(1, 99)
@export var wait_time := 1.0

@onready var timer := $Timer
var level : int


func _ready() -> void:
	level = DAT.get_character("greg").level


func _on_timer_timeout() -> void:
	timer.start(wait_time)
	if not Math.inrange(level, active_range.x, active_range.y): return
	if enemy_amount < max_enemies and randf() <= 0.25:
		enemy_amount += 1
		var thug = spawn_enemy.instantiate()
		if thug is OverworldCharacter:
			thug = thug as OverworldCharacter
			thug.save = false
			if player:
				thug.chase_target = player
		add_child(thug)
		thug.global_position += Vector2(randf_range(-5, 5), randf_range(-5, 5))
		# cool fade in when the enemy spawns
		thug.modulate.a = 0
		var tw := create_tween()
		tw.tween_property(thug, "modulate:a", 1.0, 0.33)
