extends Node

# handles data, saving and loading it
# ...and a bunch of other things.

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
const NEIGHBOUR_WIFE_CYCLE := 470

# on death
var death_reason := "default"
var last_save_file := 0


func _init() -> void:
	randomize()


func _ready() -> void:
	load_characters()
	load_items()
	load_spirits()
	set_data("party", ["greg"])
	if get_current_scene().get_script() == self.get_script():
		var libel := Label.new()
		libel.text = "Hello world, DAT"
		add_child(libel)


func load_characters() -> void:
	for s in character_list.split("\n"):
		character_dict[s] = load(DIR.get_char_path(s)) as Character
		character_dict[s].name_in_file = s


func load_items() -> void:
	for s in item_list.split("\n"):
		item_dict[s] = load(DIR.get_item_path(s)) as Item
		item_dict[s].name_in_file = s


func load_spirits() -> void:
	for s in spirit_list.split("\n"):
		spirit_dict[s] = load(DIR.get_spirit_path(s)) as Spirit
		spirit_dict[s].name_in_file = s


# entry point for a new game.
func start_game() -> void:
	A.clear()
	set_data("party", ["greg"])
	LTS.level_transition("res://scenes/cutscene/scn_intro.tscn", {"fade_time": 2.0})


func set_data(key, value) -> void:
	if log_dat_chgs(): print("data key %s set to %s" % [key, value])
	A[key] = value


func get_data(key: String, default = null):
	if log_dat_chgs(): print("requested key %s from data" % key)
	return A.get(key, default)


func incrf(key: String, amount: float) -> void:
	if log_dat_chgs(): print("floatcrementing: ")
	set_data(key, A.get(key, 0.0) + amount)


func incri(key: String, amount: int) -> void:
	if log_dat_chgs(): print("intcrementing: ")
	set_data(key, A.get(key, 0) + amount)


func save_data(filename := "save.grs", overwrite := true) -> void:
	save_nodes_data()
	save_chars_to_data()
	set_data("playtime", seconds)
	set_data("save_file", filename)
	set_data("date", Time.get_date_string_from_system())
	set_data("time", Time.get_time_string_from_system())
	last_save_second = seconds
	
	var stuff := {}
	if not overwrite:
		stuff = DIR.get_dict_from_file(filename)
		for k in A.keys():
			stuff[k] = A[k]
	else:
		stuff = A
	
	DIR.write_dict_to_file(stuff, filename)


func force_data(key: String, value: Variant, filename := "") -> void:
	if not filename.length():
		filename = get_data("save_file", "save.grs")
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


func capture_player(type := "", overlap := true) -> void:
	if not overlap and type in player_capturers: return
	print(type, " captured player")
	player_capturers.append(type)
	var player := get_tree().get_first_node_in_group("players")
	if is_instance_valid(player):
		player.state = PlayerOverworld.States.NOT_FREE_MOVE


func free_player(type := "") -> void:
	print("freed player from ", type)
	player_capturers.erase(type)
	if type == "all":
		player_capturers.clear()
	if player_capturers.size() > 0: return
	var player := get_tree().get_first_node_in_group("players")
	if is_instance_valid(player):
		player.state = PlayerOverworld.States.FREE_MOVE


func grant_item(item : StringName, party_index := 0, dialogue := true) -> void:
	get_character(A.get("party", ["greg"])[party_index]).inventory.append(item)
	if DAT.get_current_scene().name == "Battle":
		var battle = DAT.get_current_scene()
		if battle.party.is_empty(): return
		battle.party[party_index].character.inventory.append(item)
	if not dialogue: return
	SOL.dialogue_box.dial_concat("getitem", 0, [get_item(item).name])
	SOL.dialogue("getitem")


func grant_silver(amount: int, dialogue := true) -> void:
	var dialid := "getsilver"
	if amount < 0: dialid = "losesilver"
	set_data("silver", A.get("silver", 0) + amount)
	if not dialogue: return
	SOL.dialogue_box.dial_concat(dialid, 0, [absi(amount)])
	SOL.dialogue(dialid)


func grant_spirit(spirit : StringName, party_index := 0, dialogue := true) -> void:
	var charc : Character = get_character(A.get("party", ["greg"])[party_index])
	var uuspirits : Array[String] = charc.unused_sprits.duplicate()
	uuspirits.append(spirit)
	charc.unused_sprits = uuspirits
	if DAT.get_current_scene().name == "Battle":
		var battle = DAT.get_current_scene()
		if !battle.party.is_empty():
			var character_is : Character = battle.party[party_index].character
			var list : Array[String] = character_is.unused_sprits.duplicate()
			list.append(spirit)
			character_is.unused_sprits = list
	if not dialogue: return
	SOL.dialogue_box.dial_concat("getspirit", 0, [get_spirit(spirit).name])
	SOL.dialogue("getspirit")


func get_current_scene() -> Node:
	return get_tree().root.get_child(-1)


func get_character(key: String) -> Character:
	if not key in character_dict:
		print("char ", key, " not found")
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
	if not id in item_dict:
		print("item ", id, " not found")
		return preload("res://resources/items/res_default_item.tres")
	return item_dict[id]


func get_spirit(id: String) -> Spirit:
	if not id in spirit_dict:
		print("spirit ", id, " not found")
		return preload("res://resources/res_default_spirit.tres")
	return spirit_dict[id]


func _on_game_timer_timeout() -> void:
	seconds += 1


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


func log_dat_chgs() -> bool:
	return bool(OPT.get_opt("log_data_changes"))



