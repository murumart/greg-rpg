extends Resource
class_name BattleInfo

# resource to store info about battles

@export var enemies: Array[StringName] = []
@export var background := "town"
@export var music := ""
@export var party: Array[StringName] = []
@export var death_reason := "default"
@export var start_text := ""
@export var rewards: BattleRewards = null
#@export var victory_music := true
@export var victory_music := &"victory"
@export var stop_music_before_end := true
@export var kill_music := true
@export var play_fanfare := true
@export var crits_enabled := true


func set_enemies(x: Array[StringName]) -> BattleInfo:
	enemies = x
	return self


func set_background(x: String) -> BattleInfo:
	background = x
	return self


func set_music(x: String) -> BattleInfo:
	music = x
	return self


func set_party(x: Array[StringName]) -> BattleInfo:
	party = x
	return self


func set_death_reason(x: String) -> BattleInfo:
	death_reason = x
	return self


func set_start_text(x: String) -> BattleInfo:
	start_text = x
	return self


func set_rewards(x: BattleRewards) -> BattleInfo:
	rewards = x
	return self


func get_level() -> int:
	var levelee := 0
	for e in enemies:
		var enemy: Character = ResMan.get_character(e)
		levelee += enemy.level
	return levelee


func get_(x: StringName, default) -> Variant:
	if get(x):
		return get(x)
	else:
		return default


func _to_string() -> String:
	return str(
		"BattleInfo(",
		"enemies=", enemies, ", ",
		"background=", background, ", ",
		"music=", music, ", ",
		"party=", party, ", ",
		"death_reason=", death_reason, ", ",
		"start_text=", start_text, ", ",
		"rewards=", rewards, ", ",
		"victory_music=", victory_music, ", ",
		"stop_music_before_end=", stop_music_before_end, ") "
	)


func _before_load() -> void:
	var bike_ghosts_fought := DAT.get_data("bike_ghosts_fought", []) as Array
	var to_remove := []
	for enemy in enemies:
		if (enemy == &"bike_ghost" and not 0 in bike_ghosts_fought
				or enemy == &"bike_ghost_beta" and not 1 in bike_ghosts_fought):
			to_remove.append(enemy)
	if to_remove.size() >= enemies.size():
		rewards = null
	for x in to_remove:
		enemies.erase(x)
