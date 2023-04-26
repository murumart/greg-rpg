extends Button

# button that returns assigned data when pressed (usually using focus system)

signal return_reference(reference)
signal selected(message: String)
signal selected_return_reference(reference)

var reference

@export var description := ""


func _init() -> void:
	focus_entered.connect(_focus_entered)
	focus_exited.connect(_focus_exited)


func _ready() -> void:
	if self == get_tree().get_first_node_in_group("reference_buttons"):
		call_deferred("grab_focus")


func _focus_entered() -> void:
	selected.emit(description)
	selected_return_reference.emit(reference)


# moving to another button plays the menu sound
func _focus_exited() -> void:
	if visible:
		SND.menusound(1.5)


func _pressed() -> void:
	if is_instance_valid(reference) or reference != null:
		return_reference.emit(reference)
		SND.menusound()
