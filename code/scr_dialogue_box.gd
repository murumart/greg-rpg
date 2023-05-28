extends Node2D
class_name DialogueBox

# main game dialogue box

signal dialogue_closed
signal started_speaking
signal changed_dialogue
signal finished_speaking

@onready var textbox : TextBox = $DialogueBoxPanel/DialogueTextbox
@onready var portrait : Sprite2D = $DialogueBoxPanel/PortraitSprite
@onready var reference_button := $DialogueBoxPanel/ReferenceButton
@onready var choices_container := $DialogueBoxPanel/ScrollContainer/ChoicesContainer
@onready var finished_marker := $DialogueBoxPanel/FinishedMarker
@onready var dialogue_sound : AudioStreamPlayer = get_node_or_null("DialogueSound")

@export var dont_close := false # used in mail man kiosk mostly

const PORTRAIT_DIR := "res://sprites/characters/portraits/spr_portrait_%s.png"

var dialogue_queue : Array[Dialogue] = []

var loaded_dialogue : Dialogue
var loaded_dialogue_line : DialogueLine
var current_dialogue : int

var current_choice := &"": set = _set_current_choice
var choices_open := false

var dialogues_dict := {}

var unmodified_dialogue_lines := {}

var default_textbox_size := Vector2()
var default_textbox_position := Vector2()


func _ready() -> void:
	hide()
	load_dialogue_dict()
	default_textbox_size = textbox.size
	default_textbox_position = textbox.position


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_instance_valid(loaded_dialogue): return
	if loaded_dialogue.size() < 1: return
	if event.is_action_pressed("ui_accept") and not is_speaking() and not choices_open:
		next_dialogue_requested()
		get_viewport().set_input_as_handled()
	# pressing z or x allows skipping the babbling
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		skip()


# load the dialogues from files
func load_dialogue_dict() -> void:
	dialogues_dict =\
	DialogueParser.parse_dialogue_from_file(FileAccess.open("res://resources/res_dialogue.txt", FileAccess.READ))
	
	var fish_dialogues := DialogueParser.parse_dialogue_from_file(FileAccess.open("res://resources/res_fisher_dialogue.txt", FileAccess.READ))
	for i in fish_dialogues.keys():
		dialogues_dict[i] = fish_dialogues[i]


func prepare_dialogue(key: String) -> void:
	if dialogues_dict.is_empty():
		load_dialogue_dict()
	assert(key in dialogues_dict.keys(), "no key %s in dialogues" % key)
	if is_instance_valid(loaded_dialogue):
		# if a dialogue is loaded, add the new one to the queue
		# first we duplicate the new dialogue
		var dial_to_append : Dialogue = dialogues_dict.get(key, Dialogue.new()).duplicate(true)
		# then assign a new typed array variable.
		var new_lines : Array[DialogueLine] = []
		# and put the lines of the new dialogue... inside this array...
		for l in dial_to_append.lines:
			var line : DialogueLine = l.duplicate(true)
			new_lines.append(line)
		# and then set the new dialogue's lines like this.
		dial_to_append.lines = new_lines
		# why all this? ha ha ha! typed array jank!!!!  god dannnnnnnn
		dialogue_queue.append(dial_to_append)
		return
	load_dialogue(dialogues_dict.get(key, Dialogue.new()))
	set_finished_marker(0)


func load_dialogue(dial : Dialogue) -> void:
	loaded_dialogue = dial
	changed_dialogue.emit()
	if loaded_dialogue.alias != "":
		var alias := loaded_dialogue.alias
		loaded_dialogue = null
		prepare_dialogue(alias)
		return
	DAT.capture_player("dialogue", false)
	assert(is_instance_valid(loaded_dialogue) and loaded_dialogue.size() > 0)
	current_dialogue = 0
	speak_this_dialogue_part(loaded_dialogue.get_line(current_dialogue))


func speak_this_dialogue_part(part: DialogueLine) -> void:
	# get the data from the dialogue resource
	loaded_dialogue_line = null
	var text := part.text
	var character_load : String = part.character
	var character : Character = null
	var text_speed : float = part.text_speed
	var choice_link : StringName = part.choice_link
	var data_link : StringName = part.data_link
	var choices : PackedStringArray = part.choices
	var emotion : String = part.emotion
	# if the line is linked to a choice or bool data, skip to the next one
	if choice_link != &"" and (choice_link != current_choice):
		next_dialogue_requested()
		return
	if data_link != &"" and not DAT.get_data(data_link, false):
		next_dialogue_requested()
		return
	if part.sound:
		SND.play_sound(part.sound)
	
	# the false here means that you shouldn't speak the default granting dialogue!
	if part.item_to_give:
		DAT.grant_item(part.item_to_give, 0, false)
	if part.spirit_to_give:
		DAT.grant_spirit(part.spirit_to_give, 0, false)
	if part.silver_to_give:
		DAT.grant_silver(part.silver_to_give, false)
	
	if part.set_data.size() > 0:
		var key : String = part.set_data[0]
		var read : String = part.set_data[1]
		var value : Variant = 0
		if read.is_valid_float(): value = float(read)
		# gryyh
		elif read == "true": value = true
		elif read == "false": value = false
		else: value = read
		DAT.set_data(key, value)
	
	loaded_dialogue_line = part
	
	portrait.texture = null
	load_reference_buttons([], choices_container)
	choices_container.get_parent().hide()
	choices_open = false
	
	if character_load:
		character = DAT.get_character(character_load)
	
	if character and character.portrait:
		portrait.texture = character.portrait
		if DIR.portrait_exists(character.name_in_file + "_" + emotion):
			portrait.texture = load(PORTRAIT_DIR % (character.name_in_file + "_" + emotion))
	
	portrait.visible = portrait.texture != null
	set_textbox_width_to_full(not portrait.visible)
	
	set_finished_marker(0)
	
	show()
	textbox.set_text(text)
	started_speaking.emit()
	# speaking takes as much time as many there are letters to speak
	textbox.speak_text({"speed": OPT.get_opt("text_speak_time") / text_speed * text.length() * 0.05})
	if character and character.voice_sound and dialogue_sound:
		dialogue_sound.stream = character.voice_sound
	else:
		dialogue_sound.stream = preload("res://sounds/talking/snd_telegram.ogg")
	dialogue_sound.play()
	await textbox.speak_finished
	if dialogue_sound:
		dialogue_sound.stop()
	if part.instaskip:
		next_dialogue_requested()
		return
	
	set_finished_marker(1 if current_dialogue < loaded_dialogue.size() -1 else 2)
	
	if choices:
		load_reference_buttons(choices, choices_container)
		choices_container.get_parent().show()
		choices_open = true
		choices_container.get_child(0).call_deferred("grab_focus")
		set_finished_marker(0)
	
	finished_speaking.emit()


func next_dialogue_requested() -> void:
	current_dialogue += 1
	if is_instance_valid(loaded_dialogue_line) and loaded_dialogue_line.loop > -1:
		# looping back to an earlier dialogue
		current_dialogue = loaded_dialogue_line.loop
	if not current_dialogue < loaded_dialogue.size():
		# if that was the last line
		close()
	else:
		# if there are more lines
		speak_this_dialogue_part(loaded_dialogue.get_line(current_dialogue))


func skip() -> void:
	if is_speaking():
		textbox.skip_to_end()
		textbox.speak_finished.emit() # yeah
		get_viewport().set_input_as_handled()


func close(sig := true) -> void:
	loaded_dialogue = null
	loaded_dialogue_line = null
	current_dialogue = 0
	if dialogue_queue.size() > 0:
		print("queue in action")
		load_dialogue(dialogue_queue.pop_front())
		return
	if not dont_close:
		hide()
	DAT.call_deferred("free_player", "dialogue")
	if sig: call_deferred("emit_signal", "dialogue_closed")


# the size of the text area changes based on whether
# there's a portrait to display or not
func set_textbox_width_to_full(which: bool) -> void:
	if not which:
		textbox.size = default_textbox_size - Vector2(25, 0)
		textbox.position = default_textbox_position + Vector2(25, 0)
		return
	textbox.size = default_textbox_size
	textbox.position = default_textbox_position


func is_speaking() -> bool:
	return not textbox.visible_ratio == 1.0


func adjust_line(key: String, line_id: int, to: String) -> void:
	adjust(key, line_id, "text", to)


func adjust(key: String, line_id: int, param: String, to: Variant) -> void:
	dialogues_dict.get(key).get_line(line_id).set(param, to)


# replace the %s in dialogue strings with something else
func dial_concat(key: String, line_id: int, params: Array) -> void:
	var get_key := key + "_" + str(line_id)
	if not unmodified_dialogue_lines.get(get_key, false):
		# if the line has not been modified yet:
		var line := DialogueLine.new()
		line = dialogues_dict.get(key).get_line(line_id).duplicate()
		# we store the unmodified form
		unmodified_dialogue_lines[get_key] = line
	# and then copy the unmodified form and modify it
	var line : DialogueLine = dialogues_dict.get(key).get_line(line_id)
	# and store it in the regular dialogues
	line.text = unmodified_dialogue_lines.get(get_key).text % params


# for dialogue options
func load_reference_buttons(array: Array, container: Node, clear := true) -> void:
	if clear:
		for c in container.get_children():
			c.queue_free()
	for i in array.size():
		var reference = array[i]
		var refbutton := reference_button.duplicate()
		refbutton.reference = reference
		refbutton.text = str(reference)
		refbutton.connect("return_reference", _reference_button_pressed)
		refbutton.connect("selected_return_reference", _on_button_reference_received)
		container.add_child(refbutton)
		refbutton.show()
	# cool moment here where I decide that there are no more than 1 container.
	for c in container.get_child_count():
		var child : Control = container.get_child(c)
		child.focus_neighbor_top = container.get_child(c - 1).get_path()
		child.focus_neighbor_bottom = container.get_child(wrapi(c + 1, 0, container.get_child_count())).get_path()


# selecting choices
func _reference_button_pressed(reference) -> void:
	current_choice = reference
	SOL.dialogue_choice = reference
	next_dialogue_requested()
	get_viewport().set_input_as_handled()


# the little triangle or box at the corner
func set_finished_marker(to: int) -> void:
	if to < 1:
		finished_marker.hide()
	elif to == 1:
		finished_marker.region_rect.position.x = 20.0
		finished_marker.show()
	else:
		finished_marker.region_rect.position.x = 16.0
		finished_marker.show()


func _on_button_reference_received(_reference) -> void:
	pass


func _set_current_choice(to: StringName) -> void:
	current_choice = to
	print("setting current choice to  ", to)

