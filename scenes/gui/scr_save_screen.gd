extends Control
class_name SaveScreen

# little save and load popup

enum {SAVE, LOAD}
const SAVE_PATH := "greg_save_%s.grs"
const ABSOLUTE_SAVE_PATH := "user://greg_rpg/greg_save_%s.grs"

@onready var file_container := $Panel/FileContainer
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
	set_current_button(0)
	# find current save file number to highlight it
	var save_file_name: String = DAT.get_data("save_file", "")
	var save_file_nr := save_file_name.trim_prefix("greg_save_").trim_suffix(".grs")
	if save_file_nr.is_valid_float():
		set_current_button(int(save_file_nr))
	get_window().gui_release_focus()


# i just bit an apple and its skin got stuck between my two front teeth
# how do i get it ou
# welp
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if event.is_action_pressed("ui_menu") and load_warning_message:
		OS.shell_open(ProjectSettings.globalize_path(DIR.GREG_USER_FOLDER_PATH))
		return
	# exiting the save menu
	# by popular demand: you can use multiple keys to do it
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_menu") or event.is_action_pressed("escape"):
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
		if erasure_enabled:
			SOL.dialogue("save_deletion_confirmation")
			SOL.dialogue_closed.connect(func():
				if SOL.dialogue_choice != &"no":
					DirAccess.remove_absolute(ABSOLUTE_SAVE_PATH % current_button)
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
	if not Math.inrange(current_button, 0, file_count):
		return
	file_container.get_child(to).self_modulate = Color.CYAN
	var path := SAVE_PATH % current_button
	var data: Dictionary
	if DIR.file_exists(ABSOLUTE_SAVE_PATH % current_button):
		data = DIR.get_dict_from_file(path)
	if not data.is_empty():
		var text := "[center]save file info[/center]\n"
		text += "\ndate: %s\n" % data.get("date", "?")
		text += "time: %s\n" % data.get("time", "?")
		text += "playtime: %s\n" % get_playtime(data)
		text += "\nparty: %s\n" % data.get("party", "?")
		text += "level: %s\n" % data.get("char_greg_save", {}).get("level", "?")
		text += version_string(data)
		if erasure_enabled:
			text += "\npress del to erase this file."
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
				child.disabled = false
			LOAD:
				child.disabled = !DIR.file_exists(ABSOLUTE_SAVE_PATH % i)


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


func _on_button_pressed(reference: Variant) -> void:
	update_buttons()
	match mode:
		SAVE:
			DAT.save_data(SAVE_PATH % reference)
			SND.menusound()
			set_current_button(reference)
			SOL.vfx_damage_number(file_container.get_child(current_button).global_position - Vector2(SOL.SCREEN_SIZE) / 2.0 + file_container.get_child(current_button).size / 2.0, "saved!")
		LOAD:
			if load_warning_message:
				SOL.dialogue("load_warning_" + load_warning_message)
				await SOL.dialogue_closed
				if SOL.dialogue_choice != "yes":
					return
			DAT.load_data(SAVE_PATH % reference)
			set_current_button(12839)
			DAT.free_player("save_screen")
			queue_free()


func _tree_exiting() -> void:
	SOL.save_menu_open = false


func version_string(data: Dictionary) -> String:
	if data.is_empty():
		load_warning_message = "empty"
		return ""
	var version := data.get("version", Vector3(-4, 0, 4)) as Vector3
	var super_difference := DAT.VERSION.x - version.x as int
	var major_difference := DAT.VERSION.y - version.y as int
	var minor_difference := DAT.VERSION.z - version.z as int
	var text := ""
	if not version == Vector3(-4, 0, 4):
		text += "version: %s\n" % DAT.version_str(version)
	else:
		text += "unknown version"
	if super_difference:
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
