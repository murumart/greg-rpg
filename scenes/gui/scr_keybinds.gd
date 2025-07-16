class_name KeybindsSettings extends Panel

enum {CODE = 0, COLUMN = 1, INPUT = 2}

const CHANGEABLE := {
	"ui_accept": "accept",
	"cancel": "cancel",
	"menu": "menu",
	"move_up": "up",
	"move_down": "down",
	"move_left": "left",
	"move_right": "right",
	"ui_up": "ui up",
	"ui_down": "ui down",
	"ui_left": "ui left",
	"ui_right": "ui right",
	"quick_save": "save",
	"quick_load": "load",
	"screenshot": "screenshot",
}
const COLUMNS := 3

@onready var table := $ItemList as ItemList
@onready var key_listen_panel := $KeyListenPanel


func _ready() -> void:
	table.item_selected.connect(_item_selected)


func display() -> void:
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_load_table()


func discard() -> void:
	hide()
	save_inputs()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	SND.menusound(0.75)


func _load_table() -> void:
	var joypad_connected := not Input.get_connected_joypads().is_empty()

	table.clear()
	for code in CHANGEABLE:
		var code_id := table.add_item(CHANGEABLE[code])
		table.set_item_disabled(code_id, true)
		var inps := InputMap.action_get_events(code).filter(func(a: InputEvent):
			if not joypad_connected:
				return a is InputEventKey
			return a is InputEventKey or a is InputEventJoypadButton)
		for column in COLUMNS:
			if column >= inps.size():
				var id := table.add_item(".")
				table.set_item_metadata(id, [code, column, null])
				continue
			var input := inps[column] as InputEvent
			var key_name := (input.as_text()
					.to_lower()
					.trim_suffix(" (physical)")
					.trim_prefix("joypad button ")
					.left(11))
			var id := table.add_item(key_name)
			table.set_item_metadata(id, [code, column, input])


var metadata: Array


func _item_selected(idx: int) -> void:
	metadata = table.get_item_metadata(idx)

	key_listen_panel.show()
	key_listen_panel.grab_focus()


func _on_key_listen_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if metadata[INPUT] and InputMap.action_has_event(metadata[CODE], metadata[INPUT]):
				InputMap.action_erase_event(metadata[CODE], metadata[INPUT])
		key_listen_panel.hide()
		_load_table()
		return
	#if not event is InputEventKey:
		#return
	if not "pressed" in event:
		return
	if event.pressed and not event.is_action_pressed("escape"):
		key_listen_panel.hide()
		if metadata[INPUT] and InputMap.action_has_event(
				metadata[CODE], metadata[INPUT]):
			InputMap.action_erase_event(metadata[CODE], metadata[INPUT])
		InputMap.action_add_event(metadata[CODE], event)
		DAT.set_data("keybinds_changed", true)
		_load_table()


static func save_inputs() -> void:
	var config := ConfigFile.new()
	for action in CHANGEABLE:
		config.set_value("inputs", action, InputMap.action_get_events(action).filter(func(a):
			return a is InputEventKey))
	config.save("user://greg_rpg/keybinds.cfg")


static func load_inputs() -> void:
	var config := ConfigFile.new()
	var err := config.load("user://greg_rpg/keybinds.cfg")
	if err != OK:
		print("keybinds config file doesn't exist")
		return
	for action in CHANGEABLE:
		var events := InputMap.action_get_events(action)
		for event in events:
			if not event is InputEventKey:
				continue
			InputMap.action_erase_event(action, event)
		var cfg_events := config.get_value("inputs", action, []) as Array
		for event: InputEventKey in cfg_events:
			InputMap.action_add_event(action, event)


static func action_string(action: StringName) -> String:
	var input := InputMap.action_get_events(action).filter(func(a): return a is InputEventKey)
	if input.is_empty():
		return "unset"
	return input[0].as_text().trim_suffix(" (Physical)").to_lower()


static func capital_action_action_string_dict() -> Dictionary:
	var dict := {}
	for action: String in CHANGEABLE:
		dict[action.to_upper()] = action_string(action)
	return dict
