class_name CopyGregStatsComponent extends Node

@export_range(0.0, 1.0) var multiplier: float = 1.0


func _ready() -> void:
	# character is ready before this is ready - hopefully
	get_parent().ready.connect(func():
		var character := (get_parent() as BattleActor).character
		var greg := ResMan.get_character("greg")
		copy_stats_from(greg, character, multiplier)
	, CONNECT_ONE_SHOT)


static func copy_stats_from(
			from_character: Character,
			to_character: Character,
			_multiplier := 1.0) -> void:
	to_character.attack = maxf(to_character.attack, roundf(from_character.attack * _multiplier))
	to_character.defense = maxf(to_character.defense, roundf(from_character.defense * _multiplier))
	to_character.speed = maxf(to_character.speed, roundf(from_character.speed * _multiplier))
	to_character.level = maxi(to_character.level, roundi(from_character.level * _multiplier))
