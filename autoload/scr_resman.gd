class_name ResMan

const CHAR_PATH := "res://resources/characters/res_%s.tres"
const ITEM_PATH := "res://resources/items/res_%s.tres"
const SPIRIT_PATH := "res://resources/spirits/res_%s.tres"
const STATUS_EFFECT_TYPE_PATH := "res://resources/status_effect_types/res_%s.tres"

static var items := {}
static var spirits := {}
static var characters := {}
static var status_effect_types := {}


static func _static_init() -> void:
	load_resources()


static func get_character(key: StringName) -> Character:
	if not key in characters:
		print("char ", key, " not found")
		var charc: Character = load("res://resources/characters/res_default_character.tres").duplicate(true)
		charc.name = key
		return charc
	return characters[key]


static func get_item(id: StringName) -> Item:
	if not id in items:
		print("item ", id, " not found")
		return preload("res://resources/res_default_item.tres")
	return items[id]


static func get_spirit(id: StringName) -> Spirit:
	if not id in spirits:
		print("spirit ", id, " not found")
		return preload("res://resources/res_default_spirit.tres")
	return spirits[id]


static func get_effect(id: StringName) -> StatusEffectType:
	if not id in status_effect_types:
		print("effect type ", id, " not found")
		return StatusEffectType.new()
	return status_effect_types[id]


# loading characters, items, spirits from folders
static func load_resources() -> void:
	for s in _get_dir_contents("res://resources/characters/"):
		if not s.begins_with("res"):
			continue
		s = s.trim_prefix("res_")
		characters[s] = load(CHAR_PATH % s) as Character
		characters[s].name_in_file = s
	for s in _get_dir_contents("res://resources/items/"):
		if not s.begins_with("res"):
			continue
		s = s.trim_prefix("res_")
		items[s] = load(ITEM_PATH % s) as Item
		items[s].name_in_file = s
	for s in _get_dir_contents("res://resources/spirits/"):
		if not s.begins_with("res"):
			continue
		s = s.trim_prefix("res_")
		spirits[s] = load(SPIRIT_PATH % s) as Spirit
		spirits[s].name_in_file = s
	for s in _get_dir_contents("res://resources/status_effect_types/"):
		if not s.begins_with("res"):
			continue
		s = s.trim_prefix("res_")
		status_effect_types[s] = load("res://code/scr_status_effect_type.gd" % s) as StatusEffectType
		status_effect_types[s].s_id = s


# copied from DIR
static func _get_dir_contents(path: String, trim: String = "") -> Array[String]:
	var contents: Array[String] = []
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				pass
			else:
				# fuck you and your file suffix
				contents.append(file_name.get_basename().get_basename().get_basename().get_basename().trim_prefix(trim))
			file_name = dir.get_next()
		return contents
	else:
		printerr("path %s not good!" % path)
		return contents
