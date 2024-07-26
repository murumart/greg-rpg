class_name CopyGregStatsComponent extends Node

const LEVEL := &"level"
const ATTACK := &"attack"
const DEFENSE := &"defense"
const SPEED := &"speed"

@export_range(0.0, 1.0) var multiplier: float = 1.0
@export var to_copy: Array[StringName] = [&"level", &"attack", &"defense", &"speed"]


func _ready() -> void:
	# character is ready before this is ready - hopefully
	get_parent().ready.connect(func():
		var character := (get_parent() as BattleActor).character
		var greg := ResMan.get_character("greg")
		copy_stats_from_advanced(greg, character, multiplier, to_copy)
	, CONNECT_ONE_SHOT)


static func copy_stats_from(
			from_character: Character,
			to_character: Character,
			_multiplier := 1.0) -> void:
	to_character.attack = maxf(to_character.attack, roundf(from_character.attack * _multiplier))
	to_character.defense = maxf(to_character.defense, roundf(from_character.defense * _multiplier))
	to_character.speed = maxf(to_character.speed, roundf(from_character.speed * _multiplier))
	to_character.level = maxi(to_character.level, roundi(from_character.level * _multiplier))


static func copy_stats_from_advanced(
		from_character: Character,
		to_character: Character,
		_multiplier: float,
		which_ones: Array[StringName]) -> void:
	for stat in which_ones:
		to_character.set(stat,
				maxf(to_character.get(stat), roundf(from_character.get(stat) * _multiplier)))
