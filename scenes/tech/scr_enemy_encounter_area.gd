extends Area2D

var detection := 0.0
@export var battle : BattleInfo
@export_range(0, 1) var required_for_detection : float = 0.5
@export_range(0.1, 10) var check_time : float
@export_range(0.01, 1) var increase : float = 0.1
@export var max_battles : int
var battles_initiated : int

@export var player : PlayerOverworld

@export var debug := false

var player_in_area : bool

var timer = Timer.new()


func _ready() -> void:
	body_entered.connect(_on_area_player_entered)
	body_exited.connect(_on_area_player_exited)
	add_child(timer)
	timer.start(check_time)
	timer.timeout.connect(_on_timer_timeout)
	battles_initiated = DAT.get_data(save_key("encounter_count"), 0)


func _on_area_player_entered(_body) -> void:
	player_in_area = true


func _on_area_player_exited(_body) -> void:
	player_in_area = false


func _on_timer_timeout() -> void:
	if not player_in_area:
		detection = maxf(detection - increase, 0.0)
		if debug: print(detection)
		return
	
	# increase detection when moving, decrease when not moving
	if debug: print(player.velocity.length_squared())
	if player.velocity.length_squared() > 0.1:
		detection = minf(detection + increase, required_for_detection)
	else:
		detection = maxf(detection - increase, 0.0)
	if debug: print(detection)
	
	if detection >= required_for_detection and randf() >= detection:
		battles_initiated += 1
		detection = 0
		if not battles_initiated >= max_battles or max_battles == 0:
			if debug: print("BOO! %s battles initiated" % battles_initiated)
			else:
				LTS.enter_battle(battle)


func _save_me() -> void:
	DAT.set_data(save_key("encounter_count"), battles_initiated)


func save_key(key: String) -> String:
	return str("enemy_encounter_area_", name, "_in_", DAT.get_current_scene().name.to_snake_case(), "_", key)
