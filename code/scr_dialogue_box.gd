extends Node2D

@export var character_list : Array[Character]
@onready var textbox : TextBox = $DialogueBoxPanel/DialogueTextbox

var loaded_dialogue : Array
var loaded_dialogue_part : Array
var current_dialogue : int


func _ready() -> void:
	hide()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not is_speaking():
		next_dialogue_requested()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		if is_speaking():
			textbox.skip_to_end()


func prepare_dialogue(key: String) -> void:
	loaded_dialogue = DialogueList.get_dialogue(key)
	assert(loaded_dialogue.size() > 0)
	current_dialogue = 0
	speak_this_dialogue_part(loaded_dialogue[current_dialogue])


func speak_this_dialogue_part(part: Array) -> void:
	var text := part[DialogueList.TEXT] as String
	var character : int
	if part.size() -1 > DialogueList.TEXT:
		character = part[DialogueList.CHARACTER] 
	var text_speed : float = 1.0
	if part.size() -1 > DialogueList.CHARACTER:
		text_speed = part[DialogueList.TEXT_SPEED]
	
	show()
	textbox.set_text(text)
	textbox.speak_text({"speaking_speed": text_speed})


func next_dialogue_requested() -> void:
	current_dialogue += 1
	if not current_dialogue < loaded_dialogue.size():
		loaded_dialogue = []
		loaded_dialogue_part = []
		current_dialogue = 0
		hide()
	else:
		speak_this_dialogue_part(loaded_dialogue[current_dialogue])


func get_character(which: int) -> Character:
	if not which < character_list.size(): return preload("res://resources/res_default_character.tres")
	if not which > -1: return preload("res://resources/res_default_character.tres")
	else: return character_list[which]


func is_speaking() -> bool:
	return not textbox.visible_ratio == 1.0
