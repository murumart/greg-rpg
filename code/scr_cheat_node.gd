@tool
class_name CheatNode extends Node

@export var level_gain: int = 0
@export var new_spirits: Array[StringName] = []
@export var new_items: Array[StringName] = []
@export var replace_armour: StringName = &""
@export var replace_weapon: StringName = &""
@export var fill_resources: bool = true
@export var require_clean_greg: bool = true


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if DIR.standalone():
		printerr("CheatNode should be removed!")
		return
	var greg := DAT.get_character("greg") as Character
	if greg.level != 1:
		return
	greg.level_up(level_gain)
	greg.unused_sprits.append_array(new_spirits)
	greg.inventory.append_array(new_items)
	greg.armour = replace_armour
	greg.weapon = replace_weapon
	if fill_resources:
		greg.health = greg.max_health
		greg.magic = greg.max_magic


func _get_configuration_warnings() -> PackedStringArray:
	return ["Remove this node!"]
