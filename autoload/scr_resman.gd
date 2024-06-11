class_name ResMan # Man...

const CHAR_PATH := "res://resources/characters/res_%s.tres"
const ITEM_PATH := "res://resources/items/res_%s.tres"
const SPIRIT_PATH := "res://resources/spirits/res_%s.tres"
const STATUS_EFFECT_TYPE_PATH := "res://resources/status_effect_types/res_%s.tres"

static var items := {}
static var spirits := {}
static var characters := {}
static var status_effect_types := {}

static var gender__effects := {}
static var use__effects := {}


static func _static_init() -> void:
	var s := Time.get_ticks_msec()
	load_resources()
	print("loaded resources in " + str(Time.get_ticks_msec() - s) + "ms")


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
		printerr("effect type ", id, " not found")
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
	load_effects()


static func load_effects() -> void:
	var effnames := _get_dir_contents("res://resources/status_effect_types/").map(
		func(name: String):
			if not name.begins_with("res"):
				return null
			return StringName(name.trim_prefix("res_"))).filter(func(a): return a != null)
	for s in effnames:
		status_effect_types[s] = load(STATUS_EFFECT_TYPE_PATH % s) as StatusEffectType
		status_effect_types[s].s_id = s
	for s: StringName in effnames:
		if "_immunity" in s:
			continue
		#var cure := s + "_cure"
		var immune := s + "_immunity"
		#if not cure in status_effect_types.keys():
			#var cureeff := load(STATUS_EFFECT_TYPE_PATH % s).duplicate() as StatusEffectType
			#cureeff.turn_payload = null
			#cureeff.gender = Genders.CIRCLE[cureeff.gender]
			#status_effect_types[s] = cureeff
		if not immune in status_effect_types.keys():
			var immeff := load(STATUS_EFFECT_TYPE_PATH % s).duplicate() as StatusEffectType
			immeff.s_id = StringName(immune)
			immeff.turn_payload = null
			immeff.gender = Genders.CIRCLE[immeff.gender]
			immeff.name += " immune"
			status_effect_types[immune] = immeff
	# sort
	for s: StringName in status_effect_types:
		var eff := status_effect_types[s] as StatusEffectType
		if not gender__effects.has(eff.gender):
			gender__effects[eff.gender] = []
		gender__effects[eff.gender].append(s)
		if not use__effects.has(eff.use):
			use__effects[eff.use] = []
		use__effects[eff.use].append(s)


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
