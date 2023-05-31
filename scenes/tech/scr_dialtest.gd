extends Node2D

@onready var textedit := $SearchMenu

@onready var containers := [$ScrollContainer/HBoxContainer/VBoxContainer, $ScrollContainer/HBoxContainer/VBoxContainer2]

const reference_button := preload("res://scenes/tech/scn_reference_button.tscn")


func _ready() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	Math.load_reference_buttons(dialdict().keys(), containers, _reference_button_pressed, _on_button_reference_received, {"mouse_interaction": true, "text_left": 14})


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
	Math.load_reference_buttons(array2, containers, _reference_button_pressed, _on_button_reference_received, {"mouse_interaction": true, "text_left": 14})


func _reference_button_pressed(reference) -> void:
	SOL.dialogue(reference)
	get_window().gui_release_focus()


func _on_button_reference_received(_reference) -> void:
	pass


func dialdict() -> Dictionary:
	return SOL.dialogue_box.dialogues_dict

