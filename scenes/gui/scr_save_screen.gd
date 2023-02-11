extends CenterContainer

enum {SAVE, LOAD}
const SAVE_PATH := "greg_save_%s.grs"
const ABSOLUTE_SAVE_PATH := "user://greg_rpg/greg_save_%s.grs"

@onready var file_container := $Panel/FileContainer
@onready var tab_container := $Panel/TabContainer
var mode := SAVE

var menu_sound := preload("res://sounds/snd_gui.ogg")


func _ready() -> void:
	for i in file_container.get_child_count():
		var button : Button = file_container.get_child(i)
		button.reference = i
		button.return_reference.connect(_on_button_pressed)
	file_container.get_child(0).grab_focus()
	set_mode(mode)


func _input(event: InputEvent) -> void:
	if not event.is_pressed(): return
	if event.is_action_pressed("ui_cancel"):
		DAT.free_player("save_screen")
		queue_free()
	var move := Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")
	var old_mode := mode
	set_mode(wrapi(mode + int(move.x), 0, 2))
	if old_mode != mode:
		SND.play_sound(menu_sound)


func set_mode(to: int) -> void:
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
			DAT.free_player("save_screen")
			queue_free()
