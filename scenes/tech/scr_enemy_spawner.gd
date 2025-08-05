class_name EnemySpawner extends Node2D

# overworld npc spawner node

@export var spawn_enemy: PackedScene
@export var max_enemies := 8
var enemies: Array[OverworldCharacter]

@export var player: PlayerOverworld
@export var active_range := Vector2i(1, 99)
@export var wait_time := 1.0

@export var spawn_radius := 32.0

@onready var timer: Timer = $Timer
@onready var raycast: RayCast2D = $RayCast2D

var level: int


func _ready() -> void:
	$Sprite2D.hide()
	await get_tree().process_frame
	DAT.player_captured.connect(func(a: bool) -> void:
		if a:
			if &"cutscene" in DAT.player_capturers:
				timer.paused = true
				for e in enemies:
					if not is_instance_valid(e): continue
					e.chase_target = null
		else:
			if &"cutscene" not in DAT.player_capturers:
				timer.paused = false
				for e in enemies:
					if not is_instance_valid(e): continue
					e.chase_target = player
	)
	level = ResMan.get_character("greg").level
	_load_thugs()


func _load_thugs() -> void:
	var saved := DAT.get_data(get_save_key("thugs"), []) as Array
	for opts: Dictionary in saved:
		var pos := opts.get("global_position", self.global_position) as Vector2
		var thug := spawn_enemy.instantiate() as OverworldCharacter
		_place_thug(thug, pos)


func erase_thugs_from_mem() -> void:
	var savekey := get_save_key("thugs")
	DAT.set_data(savekey, [])
	enemies.map(func(a: Node) -> void: if is_instance_valid(a): a.queue_free())


func _on_timer_timeout() -> void:
	timer.start(wait_time)
	if not Math.inrange(level, active_range.x, active_range.y):
		return
	if (is_instance_valid(player)
			and player.global_position.distance_squared_to(global_position) < 10_000):
		return
	if enemies.size() < max_enemies and randf() <= 0.25:
		var thug := spawn_enemy.instantiate() as OverworldCharacter
		_place_thug(thug, _get_position())
		# cool fade in when the enemy spawns
		thug.modulate.a = 0
		var tw := create_tween()
		tw.tween_property(thug, "modulate:a", 1.0, 0.33)


func _get_position() -> Vector2:
	for try in 10:
		raycast.target_position = Vector2.from_angle(PI * 2 * randf()) * spawn_radius
		raycast.force_raycast_update()
		var point := raycast.get_collision_point()
		if point == Vector2.ZERO:
			point = raycast.target_position + global_position
		point -= (Vector2(8.0, 8.0) * -raycast.get_collision_normal())
		return point
	return global_position


func _place_thug(thug: OverworldCharacter, pos: Vector2) -> void:
	thug.save = false
	if player and not &"cutscene" in DAT.player_capturers:
		thug.chase_target = player
	add_child(thug)
	enemies.append(thug)
	thug.global_position = pos


func get_save_key(param: String) -> StringName:
	return "enemy_spawner_" + name + "_in_" + LTS.get_current_scene().name + "_" + param


func _save_me() -> void:
	var saved := enemies.filter(func(a):
		return (is_instance_valid(a) and a is OverworldCharacter
				and a.is_physics_processing()))
	var savekey := get_save_key("thugs")
	DAT.set_data(savekey, [])
	for thug: OverworldCharacter in saved:
		DAT.appenda(savekey, {
			"global_position": thug.global_position
		})
