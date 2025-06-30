class_name DebugDictEditor extends Node2D

signal done

@onready var key_list: ItemList = %KeyList
@onready var key_edit: TextEdit = %KeyEdit
@onready var text_value: TextEdit = %TextValue

@onready var edit_clear_button: Button = %EditClearButton
@onready var edit_confirm_button: Button = %EditConfirmButton
@onready var exit_button: Button = %ExitButton
@onready var title_text: Label = %TitleText

@onready var save_file_button: Button = %SaveFile
@onready var load_file_button: Button = %LoadFile

@onready var _ready_value := 1

@export var font: SystemFont
@export var _allow_external := false:
	set = set_external_files_enabled

var loaded_dict := {}
var _key_limit := []

var _loaded_from_file := false
var _file_path := &""

var current_key: Variant
var current_value: Variant


func _ready() -> void:
	key_list.item_selected.connect(_key_selected)
	edit_clear_button.pressed.connect(_clear_kv_display)
	edit_confirm_button.pressed.connect(_change_confirmed)
	text_value.text_changed.connect(_text_changed)
	exit_button.pressed.connect(exit)
	get_window().files_dropped.connect(_on_files_dropped)
	load_file_button.pressed.connect(_load_pressed)
	save_file_button.pressed.connect(_save_pressed)

	_clear_kv_display()
	_text_changed()

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	OPT.debug_camera_change_allowed = false
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	#load_dict(DIR.get_dict_from_file("greg_save_0.grs"))
	get_tree().paused = true
	set_external_files_enabled(_allow_external)


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	DAT.free_player("dict_editor")
	get_tree().paused = false
	get_window().files_dropped.disconnect(_on_files_dropped)


func exit() -> void:
	if _loaded_from_file:
		_loaded_from_file = false
		DIR.write_dict_to_file(loaded_dict, _file_path)
	done.emit()
	queue_free.call_deferred()


func load_dict(dict: Dictionary) -> void:
	loaded_dict = dict
	_load_dict()


func _load_dict() -> void:
	key_list.clear()
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
	_allow_external = false


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


func _on_files_dropped(files: PackedStringArray) -> void:
	if not _allow_external:
		return
	if files.size() > 1:
		return
	load_file(files[0])


func load_file(filename: String) -> void:
	var data := DIR.get_dict_from_global_file(filename)
	if not data:
		return
	load_dict(data)
	_loaded_from_file = true
	_file_path = filename


func set_external_files_enabled(to: bool) -> void:
	_allow_external = to
	if not _ready_value:
		await ready
	%FileButtons.visible = to
	%ExitButton.visible = not to


func _save_pressed() -> void:
	var filemenu := FileDialog.new()
	add_child(filemenu)
	filemenu.force_native = true
	filemenu.access = FileDialog.ACCESS_FILESYSTEM
	filemenu.size.x = 500
	filemenu.size.y = 400
	#filemenu.use_native_dialog = true
	filemenu.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	filemenu.current_file = _file_path.get_file()
	filemenu.file_selected.connect(func(path: String) -> void:
		DIR.write_dict_to_global_file(loaded_dict, path)
	)
	filemenu.current_dir = ProjectSettings.globalize_path(DIR.GREG_USER_FOLDER_PATH)
	filemenu.close_requested.connect(filemenu.queue_free)
	filemenu.popup()


func _load_pressed() -> void:
	var filemenu := FileDialog.new()
	add_child(filemenu)
	filemenu.force_native = true
	filemenu.access = FileDialog.ACCESS_FILESYSTEM
	filemenu.size.x = 500
	filemenu.size.y = 400
	#filemenu.use_native_dialog = true
	filemenu.current_dir = ProjectSettings.globalize_path(DIR.GREG_USER_FOLDER_PATH)
	filemenu.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	filemenu.file_selected.connect(load_file)
	filemenu.close_requested.connect(filemenu.queue_free)
	filemenu.popup_centered()
