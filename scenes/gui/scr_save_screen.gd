class_name SaveScreen extends Control

# little save and load popup

enum {SAVE, LOAD}
const SAVE_PATH := "greg_save_%s.grs"
const ABSOLUTE_SAVE_PATH := "user://greg_rpg/greg_save_%s.grs"
const UNKNOWN_VERSION := Vector3(-4, 0, 0)
const AUTOSAVE_NAME := "auto"

const COMPLETED_GAME := {
	#"zerma_fought": true,
	#"fought_grandma": true,
	"intro_cutscene_over": true,
	"vampire_defeated": true,
	"cashier_mean_welcomed": true,
	"cashier_nice_welcomed": true,
	"fish_fought": true,
	"president_defeated": true,
	"solar_protuberance_defeated": true,
	"heard_warstory": true,
	"fulfilled_bounty_thugs": true,
	"fulfilled_bounty_stray_animals": true,
	"fulfilled_bounty_broken_fishermen": true,
	"biking_game_played": true,
	"penni_stong_played": true,
	"quest_board_introed": true,
	"witnessed_ushanka_guy_cutscene": true,
	"bike_ghosts_fought": [0, 1], # TODO add to when another bike ghost gets added
	"gdung_floor": {"min": 2},
	"greenhouses_eaten": {"min": 1},
	"tarikas_talked_to": true,
	"atgirl_progress": {"min": 2},
	"skatings_played": {"min": 1},
	"snail_hells_survived": {"min": 1},
	"char_greg_save": {"inventory_has": ["diploma"], "defeated_has": ["car"]},
	"fishing_high_score": {"min": 400},
	"birds_scared": {"min": 25},
	"keybinds_changed": true,
	"known_status_effects": {"has": [&"regen", &"defense", &"speed", &"poison",
		&"coughing", &"shield", &"sopping", &"coughing_immunity",
		&"electric", &"inspiration", &"attack", &"fire", &"magnet"]},
}

@onready var file_container := %FileContainer
@onready var scroll_container := %SaveScroll
@onready var file_count := file_container.get_child_count()
@onready var tab_container := $Panel/TabContainer
@onready var info_label := $InfoLabel
var mode: int = SAVE
var restricted_mode := -1
var current_button := 0
var erasure_enabled := false
var load_warning_message := ""


func init(opt := {}):
	# restricted means either restricted to saving or loading
	# used to create screens that you can only use for loading
	# like after a game over or in the main menu
	restricted_mode = opt.get("restrict", -1)
	erasure_enabled = opt.get("erasure_enabled", false)


func _ready() -> void:
	SOL.save_menu_open = true
	tree_exiting.connect(_tree_exiting)
	for i in file_container.get_child_count():
		var button: Button = file_container.get_child(i)
		button.reference = i
		button.return_reference.connect(_on_button_pressed)
	set_mode(mode)
	set_current_button(1) # autosave is 0
	# find current save file number to highlight it
	var save_file_name: String = DAT.get_data("save_file", "")
	var save_file_nr := _get_file_nr(save_file_name)
	if save_file_nr.is_valid_float():
		set_current_button(int(save_file_nr) + 1) # autosave is 0
	get_window().gui_release_focus()
	get_window().files_dropped.connect(_on_files_dropped)


# i just bit an apple and its skin got stuck between my two front teeth
# how do i get it ou
# welp
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if event.is_action_pressed("menu"):
		OS.shell_open(ProjectSettings.globalize_path(DIR.GREG_USER_FOLDER_PATH))
		return
	# exiting the save menu
	# by popular demand: you can use multiple keys to do it
	if (event.is_action_pressed("cancel")
			or event.is_action_pressed("menu")
			or event.is_action_pressed("escape")) and not SOL.dialogue_open:
		DAT.free_player("save_screen")
		queue_free()
	# i like this input scheme i've devised.
	var move := Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	var old_mode := mode
	var old_button := current_button
	if not can_walk():
		return
	set_mode(wrapi(mode + int(move.x), 0, 2))
	set_current_button(wrapi(current_button - int(move.y), 0, file_count))
	if old_mode != mode:
		SND.menusound()
	if old_button != current_button:
		SND.menusound(2.0)
	if event.is_action_pressed("ui_text_delete"):
		# autosave is 0
		var abs_filename := ABSOLUTE_SAVE_PATH % (current_button - 1)
		if erasure_enabled and FileAccess.file_exists(abs_filename):
			SOL.dialogue("save_deletion_confirmation")
			SOL.dialogue_closed.connect(func():
				if SOL.dialogue_choice != &"no":
					DirAccess.remove_absolute(abs_filename)
					update_buttons()
			, CONNECT_ONE_SHOT)
	if event.is_action_pressed("ui_accept"):
		if SOL.dialogue_open:
			return
		_on_button_pressed(current_button)


# current selected button
func set_current_button(to: int) -> void:
	current_button = to
	for b in file_container.get_children():
		b.self_modulate = Color.WHITE
	var max_scroll: int = maxi(file_container.size.y - scroll_container.size.y, 0)
	scroll_container.scroll_vertical = ceili(remap(to, 0,
			file_count - 1, 0, max_scroll))
	if not Math.inrange(current_button, 0, file_count):
		return
	file_container.get_child(to).self_modulate = Color.CYAN
	var data := _get_data(current_button)
	if not data.is_empty():
		var text := "[center]save file info[/center]\n[color=#eeefef]"
		text += "\n"
		if not DIR.standalone():
			text += "file: [font_size=6]%s[/font_size]\n" % data.get("save_file", "?")
		text += "date: %s\n" % data.get("date", "?")
		text += "time: %s\n" % data.get("time", "?")
		text += "playtime: %s\n" % get_playtime(data)
		text += "level: %s\n" % data.get("char_greg_save", {}).get("level", "?")
		text += "completion: " + str(roundf(_calc_completion_percent(data))) + "%\n"
		text += "[/color]"
		text += version_string(data)
		if erasure_enabled:
			text += "\n[color=darkgray]press del to erase this file."
		info_label.set_text(text)
	else:
		var text := "[center]file empty![/center]\n"
		info_label.set_text(text)
		text += version_string(data)


# saving and loading are different modes
func set_mode(to: int) -> void:
	if restricted_mode > -1:
		to = restricted_mode
		for i in tab_container.get_child_count():
			if i != restricted_mode:
				tab_container.get_child(i).hide()
	mode = to
	for i in tab_container.get_children():
		i.modulate = Color.DARK_GRAY
		i.z_index = -1
	tab_container.get_child(mode).modulate = Color.CYAN
	tab_container.get_child(mode).z_index = 0
	update_buttons()


func update_buttons() -> void:
	for i in file_container.get_child_count():
		var child := file_container.get_child(i)
		match mode:
			SAVE:
				# autosave file
				child.disabled = is_autosave(i)
			LOAD:
				var abspath := ABSOLUTE_SAVE_PATH % (i - 1) # autosave is 0
				if is_autosave(i):
					abspath = ABSOLUTE_SAVE_PATH % AUTOSAVE_NAME
				child.disabled = not DIR.file_exists(abspath)


func get_playtime(data: Dictionary) -> String:
	var s = ""
	var secs := data.get("playtime", 0) as int
	var mins := floori(secs / 60.0)
	var hrs := floori(mins / 60.0)

	if secs <= 0:
		return "?"
	if mins < 1:
		s += str(secs) + " sec"
		return s
	if hrs < 1:
		s += str(mins) + " min"
		return s
	else:
		s += str(hrs) + "h " + str(mins - hrs * 60) + "min "

	return s


func _on_button_pressed(which_button: int) -> void:
	update_buttons()
	match mode:
		SAVE:
			if file_container.get_child(which_button).disabled:
				return
			var data := _get_data(which_button)
			var discrepancy: bool = (
					DAT.seconds < data.get("seconds", -1)
					or DAT.get_data("nr", 0) != data.get("nr", -1)
			) and not data.is_empty()
			if discrepancy:
				SOL.dialogue("save_warning_overwrite")
				await SOL.dialogue_closed
				if SOL.dialogue_choice != "yes":
					return
			which_button -= 1 # autosave is 0
			var savefile_path := SAVE_PATH % which_button
			DAT.save_data(savefile_path)
			SND.menusound()
			which_button += 1
			set_current_button(which_button)
			vfx_msg("saved!")
		LOAD:
			if load_warning_message:
				SOL.dialogue_choice = ""
				SOL.dialogue("load_warning_" + load_warning_message)
				await SOL.dialogue_closed
				if SOL.dialogue_choice != "yes":
					return
			# autosave is 0
			var savefile_path := SAVE_PATH % (which_button - 1)
			if is_autosave(which_button):
				savefile_path = SAVE_PATH % AUTOSAVE_NAME
			DAT.load_data(savefile_path)
			set_current_button(12839)
			DAT.free_player("save_screen")
			queue_free()


func _tree_exiting() -> void:
	SOL.save_menu_open = false
	get_window().files_dropped.disconnect(_on_files_dropped)


func _on_files_dropped(files: PackedStringArray) -> void:
	if files.size() > 1:
		vfx_msg("more than one file!")
		return
	var data := DIR.get_dict_from_global_file(files[0])
	if not data:
		vfx_msg("invalid file!")
		return
	SOL.dialogue("load_warning_external")
	await SOL.dialogue_closed
	if SOL.dialogue_choice != &"yes":
		vfx_msg("denied!")
		return
	DAT.load_data_from_dict(data, true)
	set_current_button(12839)
	DAT.free_player("save_screen")
	queue_free()


func version_string(data: Dictionary) -> String:
	if data.is_empty():
		load_warning_message = "empty"
		return ""
	var version := data.get("version", UNKNOWN_VERSION) as Vector3
	var _complete_comparison_version := (version.x * 10000
			+ version.y * 1000 + version.z * 100)
	var super_difference := DAT.VERSION.x - version.x as int
	var major_difference := DAT.VERSION.y - version.y as int
	var minor_difference := DAT.VERSION.z - version.z as int
	var text := ""
	if not version == UNKNOWN_VERSION:
		text += "version: %s\n" % DAT.version_str(version)
	else:
		text += "unknown version"
	if (super_difference < 0
			or (not super_difference and (major_difference < 0 or minor_difference < 0))
			or (not super_difference and not major_difference and minor_difference < 0)):
		load_warning_message = "outdatedgame"
		text = "[color=#ff0000]%s[/color]" % text
	elif super_difference:
		text = "[color=#ff0000]%s[/color]" % text
		load_warning_message = "superdiff"
	elif major_difference:
		text = "[color=#ffccaa]%s[/color]" % text
		load_warning_message = "majordiff"
	else:
		text = "[color=#aaaaaa]%s[/color]" % text
		load_warning_message = ""
	return text


func can_walk() -> bool:
	return (
		not SOL.dialogue_open
	)


func _calc_completion_percent(file: Dictionary) -> float:
	var sum := 0.0
	for key in COMPLETED_GAME:
		var value: Variant = COMPLETED_GAME[key]
		var gotten: Variant = file.get(key, null)
		var truth := true
		if value is Dictionary:
			if "min" in value:
				truth = truth and gotten != null and gotten >= value.min
			if "max" in value:
				truth = truth and gotten != null and gotten <= value.max
			if "inventory_has" in value:
				if gotten == null:
					truth = false
				else: for item in value.inventory_has:
					truth = truth and item in gotten.inventory
			if "defeated_has" in value:
				if gotten == null:
					truth = false
				else: for item in value.defeated_has:
					truth = truth and item in gotten.defeated_characters
			if "has" in value:
				if gotten == null:
					truth = false
				else: for thing in value.has:
					truth = truth and thing in gotten
		else:
			truth = value == gotten
		if truth:
			sum += 1.0
	return (sum / COMPLETED_GAME.size()) * 100.0


func vfx_msg(msg: String) -> void:
	SOL.vfx_damage_number(
			file_container.get_child(current_button).global_position
			- Vector2(SOL.SCREEN_SIZE) / 2.0
			+ file_container.get_child(current_button).size / 2.0, msg)


func is_autosave(which: int) -> bool:
	#return which >= file_container.get_child_count() - 1
	return which == 0


func _get_data(button: int) -> Dictionary:
	var path := SAVE_PATH % (button - 1) # autosave is 0
	var abspath := ABSOLUTE_SAVE_PATH % (button - 1)
	if is_autosave(button):
		path = SAVE_PATH % AUTOSAVE_NAME
		abspath = ABSOLUTE_SAVE_PATH % AUTOSAVE_NAME
	var data: Dictionary
	if DIR.file_exists(abspath):
		data = DIR.get_dict_from_file(path)
	return data


func _get_file_nr(filename: String) -> String:
	return filename.trim_prefix("greg_save_").trim_suffix(".grs")
