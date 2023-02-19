extends Node2D
class_name DialogueBox

signal dialogue_closed
signal started_speaking
signal finished_speaking

@onready var textbox : TextBox = $DialogueBoxPanel/DialogueTextbox
@onready var portrait : Sprite2D = $DialogueBoxPanel/PortraitSprite
@onready var reference_button := $DialogueBoxPanel/ReferenceButton
@onready var choices_container := $DialogueBoxPanel/ScrollContainer/ChoicesContainer

@export var dialogues : Array[Dialogue]

var loaded_dialogue : Dialogue
var loaded_dialogue_line : DialogueLine
var current_dialogue : int

var current_choice := &""
var choices_open := false

var dialogues_dict := {}

var unmodified_dialogue_lines := {
	
}


func _ready() -> void:
	hide()
	dialogues_dict = (DialogueParser.new().parse_dialogue_from_file(DIR.get_dialogue_file()))
	for i in dialogues_dict:
		dialogues.append(dialogues_dict[i])


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_instance_valid(loaded_dialogue): return
	if loaded_dialogue.size() < 1: return
	if event.is_action_pressed("ui_accept") and not is_speaking() and not choices_open:
		next_dialogue_requested()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		if is_speaking():
			textbox.skip_to_end()
			textbox.speak_finished.emit() # yeah
			get_viewport().set_input_as_handled()


func prepare_dialogue(key: String) -> void:
	loaded_dialogue = dialogues_dict.get(key, Dialogue.new())
	if loaded_dialogue.alias != "":
		prepare_dialogue(loaded_dialogue.alias)
		return
	DAT.capture_player("dialogue")
	assert(key in dialogues_dict.keys(), "no key %s in dialogues" % key)
	assert(is_instance_valid(loaded_dialogue) and loaded_dialogue.size() > 0)
	current_dialogue = 0
	speak_this_dialogue_part(loaded_dialogue.get_line(current_dialogue))


func speak_this_dialogue_part(part: DialogueLine) -> void:
	# get the data from the dialogue array
	loaded_dialogue_line = null
	var text := part.text
	var character_load : String = part.character
	var character : Character = null
	var text_speed : float = part.text_speed
	var choice_link : StringName = part.choice_link
	var choices : PackedStringArray = part.choices
	if choice_link != &"" and (choice_link != current_choice):
		next_dialogue_requested()
		return
	
	loaded_dialogue_line = part
	
	portrait.texture = null
	load_reference_buttons([], [choices_container])
	choices_container.get_parent().hide()
	choices_open = false
	
	if character_load:
		character = DAT.get_character(character_load)
	
	if character and character.portrait:
		portrait.texture = character.portrait
	
	portrait.visible = portrait.texture != null
	set_textbox_width_to_full(not portrait.visible)
	
	show()
	textbox.set_text(text)
	started_speaking.emit()
	textbox.speak_text({"speed": OPT.get_opt("text_speak_time") / text_speed})
	if character and character.voice_sound:
		SND.play_sound(character.voice_sound, {"bus": "Speech"})
	await textbox.speak_finished
	if part.instaskip:
		next_dialogue_requested()
		return
	
	if choices:
		load_reference_buttons(choices, [choices_container])
		choices_container.get_parent().show()
		choices_open = true
		choices_container.get_child(0).grab_focus()
	
	finished_speaking.emit()


func next_dialogue_requested() -> void:
	current_dialogue += 1
	if is_instance_valid(loaded_dialogue_line) and loaded_dialogue_line.loop > -1:
		current_dialogue = loaded_dialogue_line.loop
	if not current_dialogue < loaded_dialogue.size():
		loaded_dialogue = null
		loaded_dialogue_line = null
		current_dialogue = 0
		hide()
		DAT.call_deferred("free_player", "dialogue")
		call_deferred("emit_signal", "dialogue_closed")
	else:
		speak_this_dialogue_part(loaded_dialogue.get_line(current_dialogue))


func set_textbox_width_to_full(which: bool) -> void:
	if not which:
		textbox.size = Vector2i(107, 25)
		textbox.position = Vector2i(28, 3)
	else:
		textbox.size = Vector2i(132, 25)
		textbox.position = Vector2i(3, 3)


func is_speaking() -> bool:
	return not textbox.visible_ratio == 1.0


func adjust_line(key: String, line_id: int, to: String) -> void:
	adjust(key, line_id, "text", to)


func adjust(key: String, line_id: int, param: String, to: Variant) -> void:
	dialogues_dict.get(key).get_line(line_id).set(param, to)


func dial_concat(key: String, line_id: int, params: Array) -> void:
	var get_key := key + "_" + str(line_id)
	if not unmodified_dialogue_lines.get(get_key, false):
		var line := DialogueLine.new()
		line = dialogues_dict.get(key).get_line(line_id).duplicate()
		unmodified_dialogue_lines[get_key] = line
	var line : DialogueLine = dialogues_dict.get(key).get_line(line_id)
	line.text = unmodified_dialogue_lines.get(get_key).text % params


func load_reference_buttons(array: Array, containers: Array, clear := true) -> void:
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
		var refbutton := reference_button.duplicate()
		refbutton.reference = reference
		refbutton.text = str(reference)
		refbutton.connect("return_reference", _reference_button_pressed)
		refbutton.connect("selected_return_reference", _on_button_reference_received)
		containers[container_nr].add_child(refbutton)
		refbutton.show()
		container_nr = wrapi(container_nr + 1, 0, containers.size())


func _reference_button_pressed(reference) -> void:
	current_choice = reference
	SOL.dialogue_choice = reference
	next_dialogue_requested()
	get_viewport().set_input_as_handled()


func _on_button_reference_received(_reference) -> void:
	pass
