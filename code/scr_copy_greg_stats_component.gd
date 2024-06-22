class_name CopyGregStatsComponent extends Node

@export_range(0.0, 1.0) var multiplier: float = 1.0


func _ready() -> void:
	# character is ready before this is ready - hopefully
	get_parent().ready.connect(func():
		var character := (get_parent() as BattleActor).character
		var greg := ResMan.get_character("greg")
		character.attack = maxf(character.attack, roundf(greg.attack * multiplier))
		character.defense = maxf(character.defense, roundf(greg.defense * multiplier))
		character.speed = maxf(character.speed, roundf(greg.speed * multiplier))
		character.level = maxi(character.level, roundi(greg.level * multiplier))
	, CONNECT_ONE_SHOT)
