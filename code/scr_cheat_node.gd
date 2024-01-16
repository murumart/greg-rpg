@tool
class_name CheatNode extends Node

@export var target_characters: Array[StringName] = [&"greg"]
@export var level_gain: int = 0
@export var new_spirits: Array[StringName] = []
@export var new_items: Array[StringName] = []
@export var replace_armour: StringName = &""
@export var replace_weapon: StringName = &""
@export var fill_resources: bool = true
@export var require_clean_char: bool = true


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if DIR.standalone():
		printerr("CheatNode should be removed!")
		return
	for i in target_characters:
		var char := DAT.get_character(i) as Character
		if char.level != 1 and require_clean_char:
			return
		char.level_up(level_gain)
		char.unused_sprits.append_array(new_spirits)
		char.inventory.append_array(new_items)
		char.armour = replace_armour
		char.weapon = replace_weapon
		if fill_resources:
			char.health = char.max_health
			char.magic = char.max_magic


func _get_configuration_warnings() -> PackedStringArray:
	return ["Remove this node!"]
