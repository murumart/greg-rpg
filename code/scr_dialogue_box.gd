extends Node2D

@onready var textbox : TextBox = $DialogueBoxPanel/DialogueTextbox
@onready var portrait : Sprite2D = $DialogueBoxPanel/PortraitSprite

@export var dialogues : Array[Dialogue]

var loaded_dialogue : Dialogue
var loaded_dialogue_line : DialogueLine
var current_dialogue : int

var dialogues_dict := {}


func _ready() -> void:
	hide()
	for i in dialogues:
		dialogues_dict[i.name] = i


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_instance_valid(loaded_dialogue): return
	if loaded_dialogue.size() < 1: return
	if event.is_action_pressed("ui_accept") and not is_speaking():
		next_dialogue_requested()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		if is_speaking():
			textbox.skip_to_end()


func prepare_dialogue(key: String) -> void:
	DAT.capture_player()
	loaded_dialogue = dialogues_dict.get(key, Dialogue.new())
	assert(key in dialogues_dict.keys(), "no key %s in dialogues" % key)
	assert(is_instance_valid(loaded_dialogue) and loaded_dialogue.size() > 0)
	current_dialogue = 0
	speak_this_dialogue_part(loaded_dialogue.get_line(current_dialogue))


func speak_this_dialogue_part(part: DialogueLine) -> void:
	# get the data from the dialogue array
	var text := part.text
	var character_load : int = part.character
	var character : Character = null
	var text_speed : float = part.text_speed
	
	portrait.texture = null
	
	if character_load > -1:
		character = DAT.get_character(character_load)
	
	if character and character.portrait:
		portrait.texture = character.portrait
	
	portrait.visible = portrait.texture != null
	set_textbox_width_to_full(not portrait.visible)
	
	show()
	textbox.set_text(text)
	textbox.speak_text({"speaking_speed": text_speed})
	if character and character.voice_sound:
		SND.play_sound(character.voice_sound, {"bus": "Speech"})


func next_dialogue_requested() -> void:
	current_dialogue += 1
	if not current_dialogue < loaded_dialogue.size():
		loaded_dialogue = null
		loaded_dialogue_line = null
		current_dialogue = 0
		hide()
		DAT.call_deferred("free_player")
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
