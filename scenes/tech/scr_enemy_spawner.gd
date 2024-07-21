class_name EnemySpawner extends Node2D

# overworld npc spawner node

@export var spawn_enemy: PackedScene
@export var max_enemies := 8
var enemies := []

@export var player: PlayerOverworld
@export var active_range := Vector2i(1, 99)
@export var wait_time := 1.0

@onready var timer := $Timer
var level: int


func _ready() -> void:
	$Sprite2D.hide()
	await get_tree().process_frame
	level = ResMan.get_character("greg").level
	_load_thugs()


func _load_thugs() -> void:
	var saved := DAT.get_data(get_save_key("thugs"), []) as Array
	for opts: Dictionary in saved:
		var pos := opts.get("global_position", self.global_position) as Vector2
		var thug := spawn_enemy.instantiate() as OverworldCharacter
		_place_thug(thug, pos)


func _on_timer_timeout() -> void:
	timer.start(wait_time)
	if not Math.inrange(level, active_range.x, active_range.y):
		return
	if enemies.size() < max_enemies and randf() <= 0.25:
		var thug := spawn_enemy.instantiate() as OverworldCharacter
		_place_thug(thug, global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5)))
		# cool fade in when the enemy spawns
		thug.modulate.a = 0
		var tw := create_tween()
		tw.tween_property(thug, "modulate:a", 1.0, 0.33)


func _place_thug(thug: OverworldCharacter, pos: Vector2) -> void:
	thug.save = false
	if player:
		thug.chase_target = player
	add_child(thug)
	enemies.append(thug)
	thug.global_position = pos


func get_save_key(param: String) -> StringName:
	return "enemy_spawner_" + name + "_in_" + LTS.get_current_scene().name + "_" + param


func _save_me() -> void:
	var saved := enemies.filter(func(a: OverworldCharacter):
		return a.is_physics_processing())
	var savekey := get_save_key("thugs")
	DAT.set_data(savekey, [])
	for thug: OverworldCharacter in saved:
		DAT.appenda(savekey, {
			"global_position": thug.global_position
		})
