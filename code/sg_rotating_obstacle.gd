extends "res://code/path_circle_rotator.gd"


func _ready() -> void:
	super()
	if DAT.get_data(save_key("disabled"), false):
		queue_free()
		return
	var enemies := find_children("*", "CharacterBody2D")
	for en in enemies:
		if en is OverworldCharacter and en.battle_info != null:
			en.inspected.connect(func() -> void: DAT.set_data(save_key("disabled"), true))


func save_key(wht: String) -> StringName:
	return String(get_path()) + wht
