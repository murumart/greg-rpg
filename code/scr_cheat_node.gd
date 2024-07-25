@tool
class_name CheatNode extends Node

@export var target_characters: Array[StringName] = [&"greg"]
@export var level_gain: int = 0
@export var new_spirits: Array[StringName] = []
@export var new_items: Array[StringName] = []
@export var replace_spirits: Array[StringName] = []
@export var replace_items: Array[StringName] = []
@export var replace_armour: StringName = &""
@export var replace_weapon: StringName = &""
@export var force_spirits_into_use := false
@export var fill_resources: bool = true
@export var require_clean_char: bool = true
@export var remove_when_gate_id := true
@export var force_gate_id := &""
@export var data_overrides := {}
@export var add_seconds := 0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if force_gate_id:
		LTS.gate_id = force_gate_id
	if remove_when_gate_id and (LTS.gate_id != force_gate_id):
		queue_free()
		return
	if DIR.standalone():
		printerr("CheatNode should be removed!")
		return
	for k in data_overrides:
		DAT.set_data(k, data_overrides[k])
	DAT.seconds += add_seconds
	for i in target_characters:
		var charac := ResMan.get_character(i) as Character
		if charac.level != 1 and require_clean_char:
			continue
		charac.level_up(level_gain, true, false)
		charac.unused_sprits.append_array(new_spirits)
		if not force_spirits_into_use:
			while (charac.spirits.size() < Character.MAX_SPIRITS
					and not charac.unused_sprits.is_empty()):
				charac.spirits.append(charac.unused_sprits.pop_front())
		else:
			charac.spirits.append_array(charac.unused_sprits)
			charac.unused_sprits.clear()
		if replace_spirits:
			charac.spirits.clear()
			if replace_spirits[0]:
				charac.spirits.append_array(replace_spirits)
		if replace_items:
			charac.inventory.clear()
			charac.inventory.append_array(replace_items)
		charac.inventory.append_array(new_items)
		charac.armour = replace_armour
		charac.weapon = replace_weapon
		if fill_resources:
			charac.health = charac.max_health
			charac.magic = charac.max_magic
	print(self, " cheats applied.")


func _get_configuration_warnings() -> PackedStringArray:
	return ["Remove this node!"]
