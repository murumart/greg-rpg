extends Node

# handles data, saving and loading it
# ...and a bunch of other things.

signal player_captured(capture: bool)
signal resources_loaded

# DATA
var A: Dictionary

# loadable resources
var character_dict := {}
var item_dict := {}
var spirit_dict := {}
const MAX_SPIRITS := 3

# for forbidding player movement
var player_capturers := []

# counting playtime
@onready var game_timer := $GameTimer
var seconds := 0
var playtime := 0
var last_save_second := 0
var load_second := 0

# periods of time during which stuff changes in the world
const NEIGHBOUR_WIFE_CYCLE := 470
const ATGIRL_CYCLE := 1200
const PH_GUY_WAIT := 600

# on death
var death_reason := "default"
var last_save_file := 0

var cat_names := []

# debug
var check_for_key := ""

#
var süs := 0.0


func _init() -> void:
	randomize() # only place where this is called


func _ready() -> void:
	load_resources()
	init_data()
	print("DAT is ready!")
	DIR.incj(1, 1)
	await get_tree().process_frame
	test()


# loading characters, items, spirits from folders
func load_resources() -> void:
	for s in DIR.get_dir_contents("res://resources/characters/"):
		if not s.begins_with("res"): continue
		s = s.trim_prefix("res_")
		character_dict[s] = load(DIR.get_char_path(s)) as Character
		character_dict[s].name_in_file = s
	for s in DIR.get_dir_contents("res://resources/items/"):
		if not s.begins_with("res"): continue
		s = s.trim_prefix("res_")
		item_dict[s] = load(DIR.get_item_path(s)) as Item
		item_dict[s].name_in_file = s
	for s in DIR.get_dir_contents("res://resources/spirits/"):
		if not s.begins_with("res"): continue
		s = s.trim_prefix("res_")
		spirit_dict[s] = load(DIR.get_spirit_path(s)) as Spirit
		spirit_dict[s].name_in_file = s
	resources_loaded.emit()


# entry point for a new game
# the architecture for this is iffy
func start_game() -> void:
	init_data()
	LTS.level_transition("res://scenes/cutscene/scn_intro.tscn", {"fade_time": 2.0})


# set a data key to a value
func set_data(key: StringName, value) -> void:
	if log_dat_chgs():
		if key == check_for_key:
			SND.play_sound(preload("res://sounds/error.ogg"))
			SOL.vfx_damage_number(Vector2(SOL.SCREEN_SIZE / 2), str(value), Color.WHITE, 2)
		print("data key %s set to %s" % [key, value])
	A[key] = value


# get a key from the data dict, use this instead of DAT.A.get()
func get_data(key: StringName, default = null):
	if log_dat_chgs(): print("requested key %s from data" % key)
	return A.get(key, default)


# incrementing a float in the data dict
func incrf(key: StringName, amount: float) -> void:
	if log_dat_chgs(): print("floatcrementing: ")
	set_data(key, A.get(key, 0.0) + amount)


# incrementing an int in the data dict
func incri(key: StringName, amount: int) -> void:
	if log_dat_chgs(): print("intcrementing: ")
	set_data(key, A.get(key, 0) + amount)


func appenda(key: StringName, thing: Variant) -> void:
	if log_dat_chgs(): print("adding element %s to key %s" % [thing, key])
	set_data(key, Math.reaap(get_data(key, []), thing))


func save_data(filename := "save.grs", overwrite := true) -> void:
	save_nodes_data()
	save_chars_to_data()
	set_data("playtime", playtime)
	set_data("save_file", filename)
	set_data("seconds", seconds)
	# get estonianised
	set_data("date", Time.get_date_string_from_system().replace("-", "."))
	set_data("time", Time.get_time_string_from_system().replace(":", "."))
	last_save_second = seconds
	
	var stuff := {}
	# technical possibility of not replacing the entire dict but only
	# replacing existing keys and keeping ones that are not in the new one.
	# that explanation sucks
	if not overwrite:
		stuff = DIR.get_dict_from_file(filename)
		for k in A.keys():
			stuff[k] = A[k]
	else:
		stuff = A
	
	DIR.write_dict_to_file(stuff, filename)


# change some key inside the actual save file
func force_data(key: String, value: Variant, filename := "") -> void:
	if not filename.length():
		filename = get_data("save_file", "save.grs")
	var stuff := DIR.get_dict_from_file(filename)
	
	stuff[key] = value
	DIR.write_dict_to_file(stuff, filename)
	
	print("forced key %s and value %s to file %s" % [key, value, filename])


# loop through all nodes that have persistent data between scenes
func save_nodes_data() -> void:
	print("saving nodes...")
	get_tree().call_group("save_me", "_save_me")
	print("node saving end.")


func load_data(filename := "save.grs", overwrite := true) -> void:
	var loaded := DIR.get_dict_from_file(filename)
	if loaded.size() < 1: print("no data to load!"); return
	
	print("overwriting data...")
	if not overwrite:
		# again option to not overwrite everything
		for k in loaded.keys():
			A[k] = loaded[k]
	else:
		A = loaded
	seconds = loaded.get("seconds", 0)
	if get_data("save_file", "") == filename:
		playtime = maxi(playtime, get_data("playtime", 0))
		set_data("playtime", playtime)
	print("finished overwriting data.")
	
	load_chars_from_data()
	
	# change the scene to the one inside the save file
	# this resets everything and allows nodes that
	# have persistent data to load their stuff.
	capture_player("level_transition")
	var room_to_load: String = loaded.get("current_room", "test")
	LTS.gate_id = LTS.GATE_LOADING
	load_second = seconds
	LTS.change_scene_to(LTS.ROOM_SCENE_PATH % room_to_load)
	# SLIGHTLY less jarring with this fade.
	SOL.fade_screen(Color(0, 0, 0, 1), Color(0, 0, 0, 0), 0.5)


# put the save data inside a JSON string and add it to clipboard
func copy_data() -> void:
	save_nodes_data()
	save_chars_to_data()
	set_data("playtime", playtime)
	set_data("seconds", seconds)
	set_data("date", Time.get_date_string_from_system())
	set_data("time", Time.get_time_string_from_system())
	DisplayServer.clipboard_set(var_to_str(DAT.A))


func set_copied_data() -> void:
	var newd = str_to_var(DisplayServer.clipboard_get())
	if newd:
		DAT.A = newd


# this is for the overworld greg
# if greg is captured, he cannot be moved around by the player
func capture_player(type := "", overlap := true) -> void:
	if not overlap and type in player_capturers: return
	var noncap := ["dialogue", "greenhouse"]
	# multiple things can capture the player
	# they are stored as strings inside this array
	player_capturers.append(type)
	if not type in noncap: SOL.dialogue_box.close(false)
	emit_signal("player_captured", true)


# allowing the player to move again
func free_player(type := "") -> void:
	player_capturers.erase(type)
	if type == "all":
		player_capturers.clear()
	# the player can only move if the capturers array is empty
	if player_capturers.size() > 0: return
	emit_signal("player_captured", false)


func grant_item(item: StringName, party_index := 0, dialogue := true) -> void:
	get_character(A.get("party", ["greg"])[party_index]).inventory.append(item)
	if LTS.get_current_scene().name == "Battle":
		var battle = LTS.get_current_scene()
		if battle.party.is_empty(): return
		battle.party[party_index].character.inventory.append(item)
	if not dialogue: return
	SOL.dialogue_box.dial_concat("getitem", 0, [get_item(item).name])
	SOL.dialogue("getitem")


func grant_silver(amount: int, dialogue := true) -> void:
	var dialid := "getsilver"
	if amount < 0: dialid = "losesilver"
	incri("silver", amount)
	if not dialogue: return
	SOL.dialogue_box.dial_concat(dialid, 0, [absi(amount)])
	SOL.dialogue(dialid)


func grant_spirit(spirit: StringName, party_index := 0, dialogue := true) -> void:
	var charc: Character = get_character(A.get("party", ["greg"])[party_index])
	if spirit in charc.unused_sprits or spirit in charc.spirits: return
	# this implementation looks so kooky because typed arrays if i remember right
	var uuspirits: Array[String] = charc.unused_sprits.duplicate()
	uuspirits.append(spirit)
	charc.unused_sprits = uuspirits
	# horrible but necessary with the current implementation of characters
	if LTS.get_current_scene().name == "Battle":
		var battle = LTS.get_current_scene()
		if !battle.party.is_empty():
			var character_is: Character = battle.party[party_index].character
			var list: Array[String] = character_is.unused_sprits.duplicate()
			list.append(spirit)
			character_is.unused_sprits = list
	if not dialogue: return
	SOL.dialogue_box.dial_concat("getspirit", 0, [get_spirit(spirit).name])
	SOL.dialogue("getspirit")
	if not DAT.get_data("spirits_gotten", 0):
		SOL.dialogue("spirit_equip_tutorial")
	DAT.incri("spirits_gotten", 1)


func get_character(key: String) -> Character:
	if not key in character_dict:
		print("char ", key, " not found")
		var charc: Character = load("res://resources/characters/res_default_character.tres").duplicate(true)
		charc.name = key
		return charc
	return character_dict[key]


func char_save_string_key(which: String, key: String) -> String:
	return str("char_", which, "_", key)


# saving and loading characters is handled here instead of inside the character
# script itself, ulike most other things with persistent data
# usually save only characters in the player's party (usually only greg)
func save_chars_to_data(all := false) -> void:
	for c in (character_dict if all else get_data("party", ["greg"])):
		var charc: Character = character_dict[c]
		set_data(char_save_string_key(c, "save"), charc.get_saveable_dict())


func load_chars_from_data() -> void:
	for c in character_dict:
		var charc: Character = character_dict[c]
		charc.load_from_dict(get_data(char_save_string_key(c, "save"), {}))


func get_item(id: String) -> Item:
	if not id in item_dict:
		print("item ", id, " not found")
		return preload("res://resources/items/res_default_item.tres")
	return item_dict[id]


func get_spirit(id: String) -> Spirit:
	if not id in spirit_dict:
		print("spirit ", id, " not found")
		return preload("res://resources/res_default_spirit.tres")
	return spirit_dict[id]

# default spirit/item/character is gleebungus


func _on_game_timer_timeout() -> void:
	seconds += 1
	playtime += 1


# storing the level up spirit names here
func get_levelup_spirit(level: int) -> String:
	var dict := {
		11: "hotel",
		22: "peptide",
		33: "jglove",
		44: "peanuts",
		55: "littleman",
		66: "personally",
		77: "roundup",
		88: "mooncity" # <-------- (whistling noise)
	}
	return dict.get(level, "")


# if we should be logging data changes
func log_dat_chgs() -> bool:
	return bool(OPT.get_opt("log_data_changes"))


func init_data() -> void:
	A.clear()
	set_data("party", ["greg"])
	set_data("nr", randf())


func test() -> void:
	pass


