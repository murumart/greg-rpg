extends Node

# handles data, saving and loading it

# file path constants
const CHAR_PATH := "res://resources/characters/res_%s."
const ITEM_PATH := "res://resources/items/res_%s."
const SPIRIT_PATH := "res://resources/spirits/res_%s."

# DATA
var A : Dictionary

# loadable resources
@export_multiline var character_list : String = ""
var character_dict := {}
@export_multiline var item_list : String = ""
var item_dict := {}
@export_multiline var spirit_list : String = ""
var spirit_dict := {}
const MAX_SPIRITS := 3

# for forbidding player movement
var player_capturers := []

# counting playtime
@onready var game_timer := $GameTimer
var seconds := 0
var last_save_second := 0

# on death
var death_reason := "default"
var last_save_file := 0


func _init() -> void:
	randomize()


func _ready() -> void:
	load_characters()
	load_items()
	load_spirits()


func load_characters() -> void:
	for s in character_list.split("\n"):
		if DIR.file_exists(get_char_path(s), true):
			character_dict[s] = load(get_char_path(s)) as Character
			character_dict[s].name_in_file = s


func load_items() -> void:
	for s in item_list.split("\n"):
		if DIR.file_exists(get_item_path(s), true):
			item_dict[s] = load(get_item_path(s)) as Item
			item_dict[s].name_in_file = s


func load_spirits() -> void:
	for s in spirit_list.split("\n"):
		if DIR.file_exists(get_spirit_path(s), true):
			spirit_dict[s] = load(get_spirit_path(s)) as Spirit
			spirit_dict[s].name_in_file = s


# entry point for a new game.
func start_game() -> void:
	A.clear()
	set_data("party", ["greg"])
	LTS.level_transition("res://scenes/cutscene/scn_intro.tscn", {"fade_time": 2.0})


func set_data(key, value) -> void:
	A[key] = value


func get_data(key: String, default = null):
	return A.get(key, default)


func incrf(key: String, amount: float) -> void:
	set_data(key, A.get(key, 0.0) + amount)


func incri(key: String, amount: int) -> void:
	set_data(key, A.get(key, 0) + amount)


func save_data(filename := "save.grs") -> void:
	save_nodes_data()
	save_chars_to_data()
	set_data("playtime", seconds)
	last_save_second = seconds
	
	var stuff := DIR.get_dict_from_file(filename)
	for k in A.keys():
		stuff[k] = A[k]
	
	DIR.write_dict_to_file(stuff, filename)


func force_data(key: String, value: Variant, filename := "save.grs") -> void:
	var stuff := DIR.get_dict_from_file(filename)
	
	stuff[key] = value
	DIR.write_dict_to_file(stuff, filename)
	
	print("forced key %s and value %s to file %s" % [key, value, filename])


func save_nodes_data() -> void:
	print("saving nodes...")
	var saveables := get_tree().get_nodes_in_group("save_me")
	for node in saveables:
		if is_instance_valid(node) and node.has_method("_save_me"):
			node._save_me()
	print("node saving end.")


func load_data(filename := "save.grs", overwrite := true) -> void:
	var loaded := DIR.get_dict_from_file(filename)
	if loaded.size() < 1: print("no data to load!"); return
	
	print("overwriting data...")
	if not overwrite:
		for k in loaded.keys():
			A[k] = loaded[k]
	else:
		A = loaded
	seconds = loaded.get("playtime", 0)
	print("finished overwriting data.")
	
	load_chars_from_data()
	
	var room_to_load : String = loaded.get("current_room", "test")
	LTS.gate_id = LTS.GATE_LOADING
	LTS.change_scene_to(LTS.ROOM_SCENE_PATH % room_to_load)
	SOL.fade_screen(Color(0, 0, 0, 1), Color(0, 0, 0, 0), 0.5)


func print_data() -> void:
	print(A)


func capture_player(type := "") -> void:
	print(type, " captured player")
	player_capturers.append(type)
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].state = PlayerOverworld.States.NOT_FREE_MOVE


func free_player(type := "") -> void:
	print("freed player from ", type)
	player_capturers.erase(type)
	if type == "all":
		player_capturers.clear()
	if player_capturers.size() > 0: return
	var players : Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].state = PlayerOverworld.States.FREE_MOVE


func grant_item(item : StringName, party_index := 0) -> void:
	get_character(A.get("party", ["greg"])[party_index]).inventory.append(item)
	SOL.dialogue_box.dial_concat("getitem", 0, [get_item(item).name])
	SOL.dialogue("getitem")


func grant_silver(amount: int) -> void:
	var dialid := "getsilver"
	if amount < 0: dialid = "losesilver"
	set_data("silver", A.get("silver", 0) + amount)
	SOL.dialogue_box.dial_concat(dialid, 0, [absi(amount)])
	SOL.dialogue(dialid)


func grant_spirit(spirit : StringName, party_index := 0) -> void:
	get_character(A.get("party", ["greg"])[party_index]).unused_sprits.append(spirit)
	SOL.dialogue_box.dial_concat("getspirit", 0, [get_spirit(spirit).name])
	SOL.dialogue("getspirit")
	SND.play_sound(preload("res://sounds/spirit/snd_spirit_get.ogg"))


func get_current_scene() -> Node:
	return get_tree().root.get_child(-1)


func get_character(key: String) -> Character:
	if not key in character_dict:
		return load("res://resources/characters/res_default_character.tres")
	return character_dict[key]


func char_save_string_key(which: String, key: String) -> String:
	return str("char_", which, "_", key)


func save_chars_to_data() -> void:
	print("saving characters...")
	for c in character_dict:
		var charc : Character = character_dict[c]
		set_data(char_save_string_key(c, "save"), charc.get_saveable_dict())
	print("finished saving characters.")


func load_chars_from_data() -> void:
	print("loading characters...")
	for c in character_dict:
		var charc : Character = character_dict[c]
		charc.load_from_dict(get_data(char_save_string_key(c, "save"), {}))
	print("finished loading characters.")


func get_item(id: String) -> Item:
	if not id in item_dict: return preload("res://resources/items/res_default_item.tres")
	return item_dict[id]


func get_spirit(id: String) -> Spirit:
	if not id in spirit_dict: return preload("res://resources/res_default_spirit.tres")
	return spirit_dict[id]


func get_char_path(charname : String) -> String:
	if DIR.standalone():
		return CHAR_PATH % charname + "tres.remap"
	return CHAR_PATH % charname + "tres"


func get_item_path(itemname : String) -> String:
	if DIR.standalone():
		return ITEM_PATH % itemname + "tres.remap"
	return ITEM_PATH % itemname + "tres"


func get_spirit_path(spiritname : String) -> String:
	if DIR.standalone():
		return SPIRIT_PATH % spiritname + "tres.remap"
	return SPIRIT_PATH % spiritname + "tres"


func _on_game_timer_timeout() -> void:
	seconds += 1
