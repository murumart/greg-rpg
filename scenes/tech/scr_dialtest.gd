extends Node2D

@onready var textedit := $SearchMenu

@onready var containers := [$ScrollContainer/HBoxContainer/VBoxContainer, $ScrollContainer/HBoxContainer/VBoxContainer2]

const reference_button := preload("res://scenes/tech/scn_reference_button.tscn")


func _ready() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	load_reference_buttons(dialdict().keys(),)


func _on_text_edit_text_submitted(new_text: String) -> void:
	print(new_text)
	var array := dialdict().keys().duplicate()
	var array2 := []
	if new_text:
		for i in array:
			if new_text in i:
				array2.append(i)
	else:
		array2 = array
	load_reference_buttons(array2,)


func load_reference_buttons(array: Array, clear := true) -> void:
	if clear:
		for container in containers:
			for c in container.get_children():
				if c.is_connected("return_reference", _reference_button_pressed):
					c.disconnect("return_reference", _reference_button_pressed)
				if c.is_connected("selected_return_reference", _on_button_reference_received):
					c.disconnect("selected_return_reference", _on_button_reference_received)
				c.queue_free()
	var container_nr := 0
	for i in array.size():
		var reference = array[i]
		var refbutton := reference_button.instantiate()
		refbutton.reference = reference
		refbutton.text = str(reference).left(14)
		refbutton.connect("return_reference", _reference_button_pressed)
		refbutton.connect("selected_return_reference", _on_button_reference_received)
		refbutton.mouse_filter = Control.MOUSE_FILTER_STOP
		refbutton.button_mask = MOUSE_BUTTON_MASK_LEFT
		containers[container_nr].add_child(refbutton)
		refbutton.show()
		container_nr = wrapi(container_nr + 1, 0, containers.size())


func _reference_button_pressed(reference) -> void:
	SOL.dialogue(reference)
	get_window().gui_release_focus()


func _on_button_reference_received(_reference) -> void:
	pass


func dialdict() -> Dictionary:
	return SOL.dialogue_box.dialogues_dict

