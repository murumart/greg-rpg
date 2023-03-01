extends Control
class_name SaveScreen

enum {SAVE, LOAD}
const SAVE_PATH := "greg_save_%s.grs"
const ABSOLUTE_SAVE_PATH := "user://greg_rpg/greg_save_%s.grs"


@onready var file_container := $Panel/FileContainer
@onready var tab_container := $Panel/TabContainer
@onready var info_label := $InfoLabel
var mode : int = SAVE
var restricted_mode := -1
var current_button := 0

var menu_sound := preload("res://sounds/snd_gui.ogg")


func init(opt := {}):
	restricted_mode = opt.get("restrict", -1)


func _ready() -> void:
	for i in file_container.get_child_count():
		var button : Button = file_container.get_child(i)
		button.reference = i
		button.return_reference.connect(_on_button_pressed)
	set_mode(mode)
	set_current_button(0)


func _input(event: InputEvent) -> void:
	if not event.is_pressed(): return
	if event.is_action_pressed("ui_cancel"):
		DAT.free_player("save_screen")
		queue_free()
	var move := Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	var old_mode := mode
	var old_button := current_button
	set_mode(wrapi(mode + int(move.x), 0, 2))
	set_current_button(wrapi(current_button - int(move.y), 0, 3))
	if old_mode != mode:
		SND.play_sound(menu_sound)
	if old_button != current_button:
		SND.play_sound(menu_sound, {pitch = 2.0})
	if event.is_action_pressed("ui_accept"):
		_on_button_pressed(current_button)


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
	match mode:
		SAVE:
			DAT.save_data(SAVE_PATH % reference)
		LOAD:
			DAT.load_data(SAVE_PATH % reference)
			set_current_button(12839)
			DAT.free_player("save_screen")
			queue_free()
