extends Node

static var gave_levelup: bool:
	set(to):
		DAT.set_data(&"east_infactory_got_lvup", to)
	get:
		return DAT.get_data(&"east_infactory_got_lvup", false)


func _ready() -> void:
	if not gave_levelup:
		var greg := ResMan.get_character("greg")
		greg.set_max_level(greg.max_level + 17)
