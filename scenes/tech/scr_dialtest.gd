extends Node2D

@onready var textedit := $FirstScreen/SearchMenu
@onready var first_screen: Control = $FirstScreen
@onready var second_screen: Control = $SecondScreen

@onready var containers := [$FirstScreen/ScrollContainer/HBoxContainer/VBoxContainer, $FirstScreen/ScrollContainer/HBoxContainer/VBoxContainer2]
@onready var dialogue_box := $DialogueBox as DialogueBox

const reference_button := preload("res://scenes/tech/scn_reference_button.tscn")


@onready var speech_edit: TextEdit = $SecondScreen/DialogueBox2/DialogueBoxPanel/TextEdit
@onready var default_textbox_size := speech_edit.size
@onready var default_textbox_position := speech_edit.position
@onready var character_choice: OptionButton = $SecondScreen/CharacterChoice
@onready var portrait_sprite: Sprite2D = $SecondScreen/DialogueBox2/DialogueBoxPanel/PortraitSprite



func _ready() -> void:
	dialogue_box.load_dialogue_dict()
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	Math.load_reference_buttons(dialdict().keys(), containers, _reference_button_pressed, _on_button_reference_received, {"mouse_interaction": true, "text_left": 14})
	for charc in ResMan.characters:
		var chara := ResMan.get_character(charc) as Character
		character_choice.add_icon_item(chara.portrait, chara.name_in_file)


func _on_text_edit_text_submitted(new_text: String) -> void:
	print(new_text)
	dialogue_box.load_dialogue_dict()
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
	dialogue_box.prepare_dialogue(reference)
	get_window().gui_release_focus()


func _on_button_reference_received(_reference) -> void:
	pass


func dialdict() -> Dictionary:
	return dialogue_box.dialogues_dict


func _on_screen_switch_pressed() -> void:
	first_screen.visible = not first_screen.visible
	second_screen.visible = not second_screen.visible


func _on_go_button_pressed() -> void:
	var dialogue := Dialogue.new()
	var line := DialogueLine.new()
	get_window().gui_release_focus()
	line.text = speech_edit.text
	var charc := character_choice.get_item_text(character_choice.get_selected_id())
	if charc != "empty":
		line.character = charc
	dialogue.lines.append(line)
	dialogue_box.load_dialogue(dialogue)


func _on_character_choice_item_selected(index: int) -> void:
	var charc := character_choice.get_item_text(index)
	var character := ResMan.get_character(charc) as Character
	if character and character.portrait:
		portrait_sprite.texture = character.portrait
	if charc == "empty":
		portrait_sprite.texture = null

	portrait_sprite.visible = portrait_sprite.texture != null
	set_textbox_width_to_full(not portrait_sprite.visible)


func set_textbox_width_to_full(which: bool) -> void:
	if not which:
		speech_edit.size = default_textbox_size - Vector2(25, 0)
		speech_edit.position = default_textbox_position + Vector2(25, 0)
		return
	speech_edit.size = default_textbox_size
	speech_edit.position = default_textbox_position
