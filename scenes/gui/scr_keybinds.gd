extends Panel

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
}
const COLUMNS := 3

@onready var table := $ItemList as ItemList
@onready var key_listen_panel := $KeyListenPanel


func _ready() -> void:
	#get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	key_listen_panel.set_process_unhandled_key_input(false)
	_load_table()


func _load_table() -> void:
	table.clear()
	for code in CHANGEABLE:
		var code_id := table.add_item(CHANGEABLE[code])
		table.set_item_disabled(code_id, true)
		var inps := InputMap.action_get_events(code).filter(func(a: InputEvent):
			return a is InputEventKey)
		for column in COLUMNS:
			if column >= inps.size():
				var id := table.add_item(".")
				table.set_item_metadata(id, [code, column, null])
				continue
			var input := inps[column] as InputEventKey
			var key_name := input.as_text().trim_suffix(" (Physical)").to_lower()
			var id := table.add_item(key_name)
			table.set_item_metadata(id, [code, column, input])
	if table.get_selected_items().is_empty():
		table.select(1)
	table.grab_focus()


var metadata: Array


func _on_item_activated(idx: int) -> void:
	metadata = table.get_item_metadata(idx)
	
	key_listen_panel.show()
	key_listen_panel.grab_focus()
	

func _on_key_listen_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		key_listen_panel.hide()
		InputMap.action_erase_event(metadata[0], metadata[2])
		InputMap.action_add_event(metadata[0], event)
		_load_table()
