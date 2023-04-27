extends Control
class_name SaveScreen

# little save and load popup

enum {SAVE, LOAD}
const SAVE_PATH := "greg_save_%s.grs"
const ABSOLUTE_SAVE_PATH := "user://greg_rpg/greg_save_%s.grs"

@onready var file_container := $Panel/FileContainer
@onready var tab_container := $Panel/TabContainer
@onready var info_label := $InfoLabel
var mode : int = SAVE
var restricted_mode := -1
var current_button := 0


func init(opt := {}):
	# restricted means either restricted to saving or loading
	# used to create screens that you can only use for loading
	# like after a game over or in the main menu
	restricted_mode = opt.get("restrict", -1)


func _ready() -> void:
	for i in file_container.get_child_count():
		var button : Button = file_container.get_child(i)
		button.reference = i
		button.return_reference.connect(_on_button_pressed)
	set_mode(mode)
	set_current_button(0)
	# find current save file number to highlight it
	var save_file_name : String = DAT.get_data("save_file", "")
	print(save_file_name)
	var save_file_nr := save_file_name.trim_prefix("greg_save_").trim_suffix(".grs")
	print(save_file_nr)
	if save_file_nr.is_valid_float():
		set_current_button(int(save_file_nr))


# i just bit an apple and its skin got stuck between my two front teeth
# how do i get it ou
# welp
func _input(event: InputEvent) -> void:
	if not event.is_pressed(): return
	# exiting the save menu
	# by popular demand: you can use multiple keys to do it
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_menu") or event.is_action_pressed("escape"):
		DAT.free_player("save_screen")
		queue_free()
	# i like this input scheme i've devised.
	var move := Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	var old_mode := mode
	var old_button := current_button
	set_mode(wrapi(mode + int(move.x), 0, 2))
	set_current_button(wrapi(current_button - int(move.y), 0, 3))
	if old_mode != mode:
		SND.menusound()
	if old_button != current_button:
		SND.menusound(2.0)
	if event.is_action_pressed("ui_accept"):
		_on_button_pressed(current_button)


# current selected button
func set_current_button(to: int) -> void:
	current_button = to
	for b in file_container.get_children():
		b.self_modulate = Color.WHITE
	if not Math.inrange(current_button, 0, 2): return
	file_container.get_child(to).self_modulate = Color.CYAN
	var path := SAVE_PATH % current_button
	var data : Dictionary
	if DIR.file_exists(ABSOLUTE_SAVE_PATH % current_button):
		data = DIR.get_dict_from_file(path)
	var text := "[center]save file info[/center]\n"
	text += "\ndate: %s\n" % data.get("date", "?")
	text += "time: %s\n" % data.get("time", "?")
	text += "playtime: %s min\n" % round(data.get("playtime", 0) / 60.0)
	text += "\nparty: %s\n" % data.get("party", "?")
	text += "level: %s\n" % data.get("char_greg_save", {}).get("level", "?")
	info_label.set_text(text)


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


func _on_button_pressed(reference: Variant) -> void:
	update_buttons()
	match mode:
		SAVE:
			DAT.save_data(SAVE_PATH % reference)
			SND.menusound()
			set_current_button(reference)
			SOL.vfx_damage_number(file_container.get_child(current_button).global_position - Vector2(SOL.SCREEN_SIZE) / 2.0 + file_container.get_child(current_button).size / 2.0, "saved!")
		LOAD:
			DAT.load_data(SAVE_PATH % reference)
			set_current_button(12839)
			DAT.free_player("save_screen")
			queue_free()
