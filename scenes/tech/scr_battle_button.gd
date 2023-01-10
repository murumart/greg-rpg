extends Button

signal return_reference(reference)
signal selected(message: String)
signal selected_return_reference(reference)

var reference

@export var description := ""


func _init() -> void:
	focus_entered.connect(_focus_entered)
	focus_exited.connect(_focus_exited)


func _unhandled_key_input(_event: InputEvent) -> void:
	pass


func _focus_entered() -> void:
	selected.emit(description)
	selected_return_reference.emit(reference)


func _focus_exited() -> void:
	await get_tree().process_frame
	if visible:
		SND.menusound(1.5)


func _pressed() -> void:
	if is_instance_valid(reference) or reference != null:
		return_reference.emit(reference)
		SND.menusound()
