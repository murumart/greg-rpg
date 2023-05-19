extends Resource
class_name BattleInfo

# resource to store info about battles

@export var enemies : Array[String] = []
@export var background := "town"
@export var music := ""
@export var party : Array[String] = []
@export var death_reason := "default"
@export var start_text := ""
@export var rewards : BattleRewards = null
@export var victory_music := true


func set_enemies(x: Array[String]) -> BattleInfo:
	enemies = x
	return self


func set_background(x: String) -> BattleInfo:
	background = x
	return self


func set_music(x: String) -> BattleInfo:
	music = x
	return self


func set_party(x: Array[String]) -> BattleInfo:
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
		var enemy : Character = DAT.get_character(e)
		levelee += enemy.level
	return levelee


func get_(x: StringName, default) -> Variant:
	if get(x):
		return get(x)
	else:
		return default
