extends Node2D
class_name DialogueBox

# main game dialogue box

@warning_ignore("unused_signal")
signal dialogue_closed
signal started_speaking(line: int)
signal changed_dialogue
signal finished_speaking(line: int)

@onready var textbox: TextBox = $DialogueBoxPanel/DialogueTextbox
@onready var portrait: Sprite2D = $DialogueBoxPanel/PortraitSprite
@onready var reference_button := $DialogueBoxPanel/ReferenceButton
@onready var choices_container := $DialogueBoxPanel/ScrollContainer/ChoicesContainer
@onready var finished_marker := $DialogueBoxPanel/FinishedMarker
@onready var dialogue_sound: AudioStreamPlayer = get_node_or_null("DialogueSound")

@export var dont_close := false # used in mail man kiosk mostly

const PORTRAIT_DIR := "res://sprites/characters/portraits/spr_portrait_%s.png"

var dialogue_queue: Array[Dialogue] = []

var loaded_dialogue: Dialogue
var loaded_dialogue_line: DialogueLine
var current_dialogue: int

var current_choice := &"": set = _set_current_choice
var choices_open := false

var dialogues_dict := {}

var unmodified_dialogue_lines := {}

var default_textbox_size := Vector2()
var default_textbox_position := Vector2()


func _ready() -> void:
	hide()
	#_load_dialogue_files()
	default_textbox_size = textbox.size
	default_textbox_position = textbox.position


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(loaded_dialogue):
		return
	if loaded_dialogue.size() < 1:
		return
	if not event.is_pressed():
		return
	if event.is_action_pressed("ui_accept") and not is_speaking() and not choices_open:
		next_dialogue_requested()
		get_viewport().set_input_as_handled()
	# pressing x allows skipping the babbling
	elif (event.is_action_pressed("cancel")
			or event.is_action_pressed("ui_accept") and OPT.get_opt("z_skips_dialogue")):
		skip()
	elif (Input.is_action_pressed("ui_accept")
			and Input.is_action_pressed("cancel")):
		skip()
		if not choices_open:
			next_dialogue_requested()
	# grab focus on choics if it somehow got lost (spamming keys can do this)
	if ((event.is_action_pressed("ui_accept") or event.is_action_pressed("cancel"))
			and choices_open
			and not choices_container.get_children().any(func(a):
				return a.has_focus())):
		choices_container.get_child(0).grab_focus.call_deferred()


# load the dialogues from files
func _load_dialogue_files() -> void:
	dialogues_dict = {}
	load_dialogue_file("res://resources/dial_menus.dial")
	load_dialogue_file("res://resources/dial_dialogue.dial")
	load_dialogue_file("res://resources/dial_fisher_dialogue.dial")
	load_dialogue_file("res://resources/dial_status_effect_descriptions.dial")
	load_dialogue_file("res://resources/dial_res_phonecalls.dial")
	load_dialogue_file("res://resources/dial_insp.dial")


func load_dialogue_file(path: String) -> void:
	dialogues_dict.merge(
			DialogueParser.parse_dialogue_from_file(
					FileAccess.open(path, FileAccess.READ)
	))


func load_dialogue_string(string: String) -> void:
	dialogues_dict.merge(
			DialogueParser.parse_dialogue_from_string(string)
	)


func copy_dial(dial: Dialogue) -> Dialogue:
	var nd := dial.duplicate(true)
	var new_lines: Array[DialogueLine] = []
	for l in dial.lines:
		var line: DialogueLine = l.duplicate(true)
		new_lines.append(line)
	nd.lines = new_lines
	return nd


func prepare_dialogue_key(key: String) -> void:
	if dialogues_dict.is_empty():
		_load_dialogue_files()
	assert(key in dialogues_dict.keys(), "no key %s in dialogues" % key)
	prepare_dialogue_d(dialogues_dict.get(key, preload("res://resources/res_default_dialogue.tres")))


func prepare_dialogue_d(dial: Dialogue) -> void:
	if is_instance_valid(loaded_dialogue):
		# if a dialogue is loaded, add the new one to the queue
		# we duplicate the new dialogue
		dialogue_queue.append(copy_dial(dial))
		return
	load_dialogue(copy_dial(dial))
	set_finished_marker(0)


func load_dialogue(dial: Dialogue) -> void:
	loaded_dialogue = dial
	changed_dialogue.emit()
	if loaded_dialogue.alias != "":
		var alias := loaded_dialogue.alias
		loaded_dialogue = null
		prepare_dialogue_key(alias)
		return
	DAT.capture_player("dialogue", false)
	assert(is_instance_valid(loaded_dialogue), "dialogue isn't valid!")
	assert(loaded_dialogue.size() > 0, "dialogue is empty!")
	current_dialogue = 0
	speak_this_dialogue_part(loaded_dialogue.get_line(current_dialogue))


func speak_this_dialogue_part(part: DialogueLine) -> void:
	# get the data from the dialogue resource
	if not is_instance_valid(loaded_dialogue):
		return
	loaded_dialogue_line = null
	var text := part.text
	var character_load: String = part.character
	var character: Character = null
	var text_speed: float = part.text_speed
	var choice_link: StringName = part.choice_link
	var data_link: PackedStringArray = part.data_link
	var choices: PackedStringArray = part.choices
	var emotion: String = part.emotion
	# if the line is linked to a choice or bool data, skip to the next one
	if choice_link != &"" and (choice_link != current_choice):
		next_dialogue_requested()
		return
	if data_link.size() > 1:
		var key := data_link[0]
		var data_value: Variant = DAT.get_data(key, false)
		var value: Variant = Math.toexp(data_link[1])
		if value is bool:
			data_value = bool(data_value)
		elif value is int:
			data_value = int(data_value)
		elif value is float:
			data_value = float(data_value)
		elif value is String or value is StringName:
			data_value = str(data_value)
		var dcond: bool = value == data_value
		if not (dcond):
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
		var key: String = part.set_data[0]
		var read: String = part.set_data[1]
		var value: Variant = 0
		if Math.toexp(read) != null: value = Math.toexp(read)
		else: value = read
		DAT.set_data(key, value)

	loaded_dialogue_line = part

	portrait.texture = null
	Math.load_reference_buttons([], [choices_container],
			_reference_button_pressed, _on_button_reference_received)
	choices_container.get_parent().hide()
	choices_open = false

	if character_load:
		character = ResMan.get_character(character_load)

	if character and character.portrait:
		portrait.texture = character.portrait
		if DIR.portrait_exists(character.name_in_file + "_" + emotion):
			portrait.texture = load(PORTRAIT_DIR % (character.name_in_file + "_" + emotion))
		portrait.scale = part.portrait_scale

	portrait.visible = portrait.texture != null
	set_textbox_width_to_full(not portrait.visible)

	set_finished_marker(0)

	show()
	if text.contains(DialogueParser.NEW_KEY_ACTION):
		text = text.replace(DialogueParser.NEW_KEY_ACTION, "")
		var dict := KeybindsSettings.capital_action_action_string_dict()
		text = text.format(dict)
	while true:
		if randf() > 0.001 or text.contains("[") or text.contains("{"): # avoids bbcode hopefully
			break
		text = Math.typos(text)
	textbox.set_text(text)
	started_speaking.emit(current_dialogue)
	# speaking takes as much time as many there are letters to speak
	textbox.speak_text({"speed": OPT.get_opt("text_speak_time")
			/ text_speed * text.length() * 0.05})
	if character and character.voice_sound and dialogue_sound:
		dialogue_sound.stream = character.voice_sound
	else:
		dialogue_sound.stream = preload("res://sounds/talking/telegram.ogg")
	dialogue_sound.play()
	await textbox.speak_finished
	if dialogue_sound:
		dialogue_sound.stop()
	if part.instaskip:
		next_dialogue_requested()
		return

	set_finished_marker(1 if current_dialogue < loaded_dialogue.size() - 1 else 2)

	if choices:
		Math.load_reference_buttons(choices, [choices_container], _reference_button_pressed, _on_button_reference_received, {"text_left": int(choices_container.size.x * 0.25 - 1)})
		choices_container.get_parent().show()
		choices_open = true
		choices_container.get_child(0).call_deferred("grab_focus")
		set_finished_marker(0)

	finished_speaking.emit(current_dialogue)


func next_dialogue_requested() -> void:
	if not is_instance_valid(loaded_dialogue):
		return
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


func close() -> void:
	SOL.speaking = false
	textbox.skip_to_end()
	dialogue_sound.stop()
	loaded_dialogue = null
	loaded_dialogue_line = null
	current_dialogue = 0
	if dialogue_queue.size() > 0:
		load_dialogue(dialogue_queue.pop_front())
		return
	if not dont_close:
		hide()
	DAT.call_deferred("free_player", "dialogue")
	call_deferred("emit_signal", "dialogue_closed")


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


func adjust(key: String, line_id: int, param: StringName, to: Variant) -> void:
	if dialogues_dict.is_empty():
		_load_dialogue_files()
	dialogues_dict.get(key).get_line(line_id).set(param, to)


func adjust_dial(key: String, param: StringName, to: Variant) -> void:
	if dialogues_dict.is_empty():
		_load_dialogue_files()
	dialogues_dict[key].set(param, to)


# replace the %s in dialogue strings with something else
func dial_concat(key: String, line_id: int, params: Array) -> void:
	if dialogues_dict.is_empty():
		_load_dialogue_files()
	assert(key in dialogues_dict, "can't concat nonexistent line")
	var get_key := key + "_" + str(line_id)
	if not get_key in unmodified_dialogue_lines:
		# if the line has not been modified yet:
		@warning_ignore("confusable_local_declaration")
		var line: DialogueLine
		line = dialogues_dict.get(key).get_line(line_id).duplicate()
		# we store the unmodified form
		unmodified_dialogue_lines[get_key] = line
	# and then copy the unmodified form and modify it
	var line: DialogueLine = dialogues_dict.get(key).get_line(line_id)
	# and store it in the regular dialogues
	line.text = unmodified_dialogue_lines.get(get_key).text % params


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
