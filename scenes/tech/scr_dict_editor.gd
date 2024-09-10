class_name DebugDictEditor extends Node2D

signal done

@onready var key_list: ItemList = %KeyList
@onready var key_edit: TextEdit = %KeyEdit
@onready var text_value: TextEdit = %TextValue

@onready var edit_clear_button: Button = %EditClearButton
@onready var edit_confirm_button: Button = %EditConfirmButton
@onready var exit_button: Button = %ExitButton
@onready var title_text: Label = %TitleText

@export var font: SystemFont

var loaded_dict := {}
var _key_limit := []
var current_key: Variant
var current_value: Variant


func _ready() -> void:
	key_list.item_selected.connect(_key_selected)
	edit_clear_button.pressed.connect(_clear_kv_display)
	edit_confirm_button.pressed.connect(_change_confirmed)
	text_value.text_changed.connect(_text_changed)
	exit_button.pressed.connect(exit)
	
	_clear_kv_display()
	_text_changed()
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	OPT.debug_camera_change_allowed = false
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	#load_dict(DIR.get_dict_from_file("greg_save_0.grs"))


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	DAT.free_player("dict_editor")


func exit() -> void:
	done.emit()
	queue_free.call_deferred()


func load_dict(dict: Dictionary) -> void:
	loaded_dict = dict
	_load_dict()


func _load_dict() -> void:
	for key in loaded_dict:
		if not _key_limit.is_empty() and not key in _key_limit:
			continue
		key_list.add_item(str(key))
		key_list.set_item_disabled(key_list.item_count - 1, key is not String)


func handle_options(options: Dictionary) -> void:
	title_text.hide()
	if options.get("title_text", null):
		title_text.show()
		title_text.text = options.get("title_text")
	_key_limit = options.get("key_limit", [])


func _set_button_key(button: Button, key: Variant) -> void:
	button.set_meta("dict_key", key)


func _key_selected(index: int) -> void:
	current_key = key_list.get_item_text(index)
	current_value = loaded_dict[current_key]
	if not _key_limit.is_empty() and not current_key in _key_limit:
		_clear_kv_display() 
	_display_kv()


func _display_kv() -> void:
	key_edit.editable = false
	edit_confirm_button.disabled = true
	if current_key is String or current_key is StringName:
		key_edit.editable = true
		edit_confirm_button.disabled = false
	key_edit.text = str(current_key)
	text_value.hide()
	match typeof(current_value):
		TYPE_OBJECT:
			text_value.hide()
		_:
			text_value.show()
			text_value.text = var_to_str(current_value)


func _clear_kv_display() -> void:
	key_edit.editable = true
	key_edit.text = ""
	text_value.show()
	text_value.editable = true
	text_value.text = ""
	current_key = null
	current_value = null


func _can_save_value() -> bool:
	var value: Variant = str_to_var(text_value.text)
	if typeof(current_value) != typeof(value):
		return false
	if not value and not typeof(current_value) in [TYPE_BOOL, TYPE_FLOAT, TYPE_NIL, TYPE_ARRAY, TYPE_FLOAT]:
		return false
	if not current_key or not key_edit.text:
		return false
	return true


func _text_changed() -> void:
	edit_confirm_button.disabled = not _can_save_value()
	edit_confirm_button.tooltip_text = str(str_to_var(text_value.text))


func _change_confirmed() -> void:
	loaded_dict[current_key] = str_to_var(text_value.text)
