extends Button

signal return_reference(reference)
signal selected(message: String)
signal selected_return_reference(reference)

var reference

@export var description := ""


func _init() -> void:
	focus_entered.connect(_focus_entered)


func _unhandled_key_input(_event: InputEvent) -> void:
	pass


func _focus_entered() -> void:
	selected.emit(description)
	selected_return_reference.emit(reference)
	SND.menusound(1.5)


func _pressed() -> void:
	if is_instance_valid(reference) or reference != null:
		return_reference.emit(reference)
		SND.menusound()
