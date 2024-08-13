extends Node

# handles data, saving and loading it
# ...and a bunch of other things.

const VERSION := Vector3(0, 9, 9)
const GDUNG_LEVEL := 72

signal player_captured(capture: bool)

# DATA
var A: Dictionary

# for forbidding player movement
var player_capturers := []

# counting playtime
@onready var game_timer := $GameTimer
var seconds := 0
var playtime := 0
var last_save_second := 0
var load_second := 0
const SCREENSHOT_DELAY := 1800

# periods of time during which stuff changes in the world
const ATGIRL_CYCLE := 1200
const LAKE_HINT_CYCLE := 800

# on death
var death_reason := "default"
var last_save_file := 0

var cat_names := []


func _init() -> void:
	randomize() # only place where this is called


func _ready() -> void:
	init_data()
	print("DAT is ready!")
	DIR.incj(1, 1)
	DAT.set_data("dance_battle_tutorialed", true)


# entry point for a new game
# the architecture for this is iffy
func start_game() -> void:
	init_data()
	set_data("nr", randf())
	LTS.level_transition("res://scenes/cutscene/scn_intro.tscn", {"fade_time": 2.0})


# set a data key to a value
func set_data(key: StringName, value) -> void:
	if log_dat_chgs():
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


func save_to_data() -> void:
	save_nodes_data()
	save_chars_to_data()
	set_data("playtime", playtime)
	set_data("seconds", seconds)
	# get estonianised
	set_data("date", Time.get_date_string_from_system().replace("-", "."))
	set_data("time", Time.get_time_string_from_system().replace(":", "."))
	set_data("version", VERSION)


func save_data(filename := "save.grs", set_filename_data := true) -> void:
	save_to_data()
	if set_filename_data:
		set_data("save_file", filename)
	last_save_second = seconds

	var stuff := {}
	stuff = A

	DIR.write_dict_to_file(stuff, filename)


func save_autosave() -> void:
	print("autosaving!")
	var filename := get_data("save_file", "") as String
	save_data(SaveScreen.SAVE_PATH % SaveScreen.AUTOSAVE_NAME, filename == "")


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


func load_data_from_dict(dict: Dictionary, overwrite: bool) -> void:
	if dict.size() < 1:
		print("no data to load!")
		return
	if DataUpdater.needs_updating(dict):
		print("updating data dict")
		DataUpdater.update_data(dict)
	print("overwriting data...")
	if not overwrite:
		# again option to not overwrite everything
		for k in dict.keys():
			A[k] = dict[k]
	else:
		A = dict
	seconds = dict.get("seconds", 0)
	print("finished overwriting data.")

	load_chars_from_data()

	# change the scene to the one inside the save file
	# this resets everything and allows nodes that
	# have persistent data to load their stuff.
	capture_player("level_transition")
	var room_to_load: String = dict.get("current_room", "test")
	LTS.gate_id = LTS.GATE_LOADING
	load_second = seconds
	LTS.change_scene_to(LTS.ROOM_SCENE_PATH % room_to_load)
	# SLIGHTLY less jarring with this fade.
	SOL.fade_screen(Color(0, 0, 0, 1), Color(0, 0, 0, 0), 0.5)


func load_data(filename := "save.grs", overwrite := true) -> void:
	var loaded := DIR.get_dict_from_file(filename)
	load_data_from_dict(loaded, overwrite)
	if get_data("save_file", "") == filename:
		playtime = maxi(playtime, get_data("playtime", 0))
		set_data("playtime", playtime)


# put the save data inside a JSON string and add it to clipboard
func copy_data() -> void:
	save_to_data()
	DisplayServer.clipboard_set(var_to_str(DAT.A))


func set_copied_data() -> void:
	var newd = str_to_var(DisplayServer.clipboard_get())
	if newd:
		DAT.A = newd


# this is for the overworld greg
# if greg is captured, he cannot be moved around by the player
func capture_player(type := &"", overlap := false, dial_closed := true) -> void:
	if not overlap and type in player_capturers: return
	var noncap := [&"dialogue", &"greenhouse"]
	# multiple things can capture the player
	# they are stored as strings inside this array
	player_capturers.append(type)
	if not type in noncap and dial_closed:
		SOL.dialogue_box.close()
	emit_signal("player_captured", true)


# allowing the player to move again
func free_player(type := &"") -> void:
	player_capturers.erase(type)
	if type == &"all":
		player_capturers.clear()
	# the player can only move if the capturers array is empty
	if player_capturers.size() > 0: return
	emit_signal("player_captured", false)


func grant_item(item: StringName, party_index := 0, dialogue := true) -> void:
	if dialogue:
		SOL.dialogue_box.dial_concat("getitem", 0, [ResMan.get_item(item).name])
		SOL.dialogue("getitem")
	if (LTS.get_current_scene().name == "Battle"
			and not LTS.get_current_scene().party.is_empty()):
		var battle = LTS.get_current_scene()
		battle.party[party_index].character.inventory.append(item)
		return
	ResMan.get_character(A.get("party", ["greg"])[party_index]).inventory.append(item)


func grant_silver(amount: int, dialogue := true) -> void:
	var dialid := "getsilver"
	if amount < 0: dialid = "losesilver"
	incri("silver", amount)
	if not dialogue: return
	SOL.dialogue_box.dial_concat(dialid, 0, [absi(amount)])
	SOL.dialogue(dialid)


func grant_spirit(spirit: StringName, party_index := 0, dialogue := true) -> void:
	var charc: Character = ResMan.get_character(A.get("party", ["greg"])[party_index])
	if spirit in charc.unused_spirits or spirit in charc.spirits: return
	# this implementation looks so kooky because typed arrays if i remember right
	var uuspirits: Array[String] = charc.unused_spirits.duplicate()
	uuspirits.append(spirit)
	charc.unused_spirits = uuspirits
	# horrible but necessary with the current implementation of characters
	if LTS.get_current_scene().name == "Battle":
		var battle = LTS.get_current_scene()
		if !battle.party.is_empty():
			var character_is: Character = battle.party[party_index].character
			var list: Array[String] = character_is.unused_spirits.duplicate()
			list.append(spirit)
			character_is.unused_spirits = list
	if not dialogue: return
	SOL.dialogue_box.dial_concat("getspirit", 0, [ResMan.get_spirit(spirit).name])
	SOL.dialogue("getspirit")
	if not DAT.get_data("spirits_gotten", 0):
		SOL.dialogue("spirit_equip_tutorial")
	DAT.incri("spirits_gotten", 1)


func char_save_string_key(which: String, key: String) -> String:
	return "char_" + which + "_" + key


# saving and loading characters is handled here instead of inside the character
# script itself, ulike most other things with persistent data
# usually save only characters in the player's party (usually only greg)
func save_chars_to_data(dict := {}) -> void:
	for c in (dict if not dict.is_empty() else get_data("party", ["greg"])):
		save_char_to_data(c)


func save_char_to_data(chara: StringName) -> void:
	set_data(char_save_string_key(chara, "save"), ResMan.get_character(chara).get_saveable_dict())


func load_chars_from_data() -> void:
	for c in ResMan.characters:
		var charc: Character = ResMan.characters[c]
		charc.load_from_dict(get_data(char_save_string_key(c, "save"), {}))


func _on_game_timer_timeout() -> void:
	seconds += 1
	playtime += 1
	
	if seconds % 60 == 0:
		var greg := get_tree().get_first_node_in_group("players")
		if not greg:
			return
		var interval := OPT.get_opt("autosave_interval") * 60 as float
		if (seconds - last_save_second >= interval
				and not greg.saving_disabled):
			save_autosave()
	
	if playtime % 300 == 0:
		var screenies := DIR.get_screenshots()
		if screenies.is_empty():
			DIR.screenshot(true)
			return
		var time_1 := FileAccess.get_modified_time(screenies[0])
		var time_2 := Time.get_unix_time_from_system()
		if time_2 - time_1 >= SCREENSHOT_DELAY:
			DIR.screenshot(true)



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
	ResMan.kill_resources_forever()
	ResMan.load_resources()
	seconds = 0
	playtime = 0
	player_capturers.clear()
	set_data("party", ["greg"])
	set_data("nr", 0.0)
	DAT.set_data("dance_battle_tutorialed", false)


static func version_str(version: Vector3 = VERSION) -> String:
	return "%s.%s.%s" % [version.x, version.y, version.z]
