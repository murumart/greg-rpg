extends RefCounted
class_name DialogueParser

# this parses the dialogue files into the resources that the game uses
# i didn't want to do a long dictionary/json file again...

const NEW_DIAL := &"DIALOGUE "
const NEW_CHAR := &"CHAR "
const NEW_TXT_SPD := &"SPEED "
const NEW_LINE := &"\t"
const NEW_CHOICES := &"CHOICES "
const NEW_CHOICE_LINK := &"CHOICE_LINK "
const NEW_INSTASKIP := &"INSTASKIP"
const NEW_ALIAS := &"ACTUALLY "
const NEW_LOOP := &"LOOP "
const NEW_ITEM := &"ITEM "
const NEW_SPIRIT := &"SPIRIT "
const NEW_SILVER := &"SILVER "
const NEW_SOUND := &"SOUND "
const NEW_EMOTION := &"EMO "
const NEW_DATA_LINK := &"DATA_LINK "
const NEW_SET_DATA := &"SET_DATA "
const NEW_PORTRAIT_SCALE := &"PORTRAIT_SCALE "
const LB := "
"
const NEW_MACRO := &"MACRO "
const NEW_KEY_ACTION := &"ACTION_"


static func parse_dialogue_from_file(file: FileAccess) -> Dictionary:
	print("dial " + file.get_path() + " ")
	return parse_dialogue_from_string(file.get_as_text(true))


static func parse_dialogue_from_string(string: String) -> Dictionary:
	var time := Time.get_ticks_usec() # measuring the time that this takes to run
	var dialogue_dictionary: Dictionary = {}
	var dial: Dialogue
	var dial_line: DialogueLine
	var char_to_set := ""
	var text_speed_to_set := 1.0
	var choices_to_set: PackedStringArray = []
	var choice_link_to_set := ""
	var data_link_to_set := PackedStringArray()
	var instaskip_to_set := false
	var loop_to_set := -1
	var item_to_give := ""
	var spirit_to_give := ""
	var silver_to_give := 0
	var sound_to_set: AudioStream = null
	var emotion_to_set := ""
	var set_data_to_set := PackedStringArray()
	var portrait_scale_to_set := Vector2(1, 1)
	var macros := {} # value replaced by key in the final text
	var split := string.split("\n")

	# going trhough the string line by line
	var i := -1
	for line: String in split:
		i += 1
		if line.length() < 3: # skip empty lines, slight performance boost
			continue
		line = line.replace("\r\n", "\n")
		for k in macros.keys():
			line = line.replace(k, macros[k])
		if line.begins_with(NEW_MACRO):
			var t := line.trim_prefix(NEW_MACRO).split(" ")
			macros[t[0]] = t[1]
			if t[1].begins_with(NEW_KEY_ACTION):
				var action_name := t[1].trim_prefix(NEW_KEY_ACTION).to_lower()
				macros[t[0]] = KeybindsSettings.action_string(action_name)
		elif line.begins_with(NEW_DIAL):
			if not dial == null:
				# if we have a dialogue at hand, we store a duplicate of it
				dialogue_dictionary[dial.name] = dial.duplicate()
				# and then reset the var
				dial = null
			# resetting stuff that should be reset when beginning new dialogue
			char_to_set = ""
			text_speed_to_set = 1.0
			choices_to_set = []
			choice_link_to_set = ""
			data_link_to_set = []
			instaskip_to_set = false
			emotion_to_set = ""
			loop_to_set = -1
			dial = Dialogue.new()
			dial.name = line.right(-NEW_DIAL.length())
		elif line.begins_with(NEW_LINE):
			# applying dialogue line properties
			dial_line = DialogueLine.new()
			dial_line.text = line.right(-NEW_LINE.length()).replace("LB", LB)
			dial_line.character = char_to_set
			dial_line.text_speed = text_speed_to_set
			dial_line.choice_link = choice_link_to_set
			dial_line.data_link = data_link_to_set
			dial_line.instaskip = instaskip_to_set
			dial_line.loop = loop_to_set
			dial_line.item_to_give = item_to_give
			dial_line.spirit_to_give = spirit_to_give
			dial_line.silver_to_give = silver_to_give
			dial_line.sound = sound_to_set
			dial_line.emotion = emotion_to_set
			dial_line.set_data = set_data_to_set
			dial_line.portrait_scale = portrait_scale_to_set
			if choices_to_set:
				dial_line.choices = choices_to_set
				choices_to_set = []
			dial.lines.append(dial_line.duplicate())
			# and some will be reset
			dial_line = null
			instaskip_to_set = false
			loop_to_set = -1
			item_to_give = ""
			spirit_to_give = ""
			silver_to_give = 0
			sound_to_set = null
			set_data_to_set = []
			portrait_scale_to_set = Vector2(1, 1)
		# storing dialogue line properties
		elif line.begins_with(NEW_ALIAS):
			dial.alias = line.right(-NEW_ALIAS.length())
		elif line.begins_with(NEW_CHAR):
			char_to_set = line.right(-NEW_CHAR.length())
		elif line.begins_with(NEW_CHOICES):
			choices_to_set = line.right(-NEW_CHOICES.length()).split(",")
		elif line.begins_with(NEW_CHOICE_LINK):
			choice_link_to_set = line.right(-NEW_CHOICE_LINK.length())
		elif line.begins_with(NEW_DATA_LINK):
			data_link_to_set = line.right(-NEW_DATA_LINK.length()).split(",")
		elif line.begins_with(NEW_EMOTION):
			emotion_to_set = line.right(-NEW_EMOTION.length())
		elif line.begins_with(NEW_SET_DATA):
			set_data_to_set = line.right(-NEW_SET_DATA.length()).split(",")
		elif line.begins_with(NEW_INSTASKIP):
			instaskip_to_set = true
		elif line.begins_with(NEW_TXT_SPD):
			text_speed_to_set = float(line.right(-NEW_TXT_SPD.length()))
		elif line.begins_with(NEW_LOOP):
			loop_to_set = int(line.right(-NEW_LOOP.length()))
		elif line.begins_with(NEW_ITEM):
			item_to_give = str(line.right(-NEW_ITEM.length()))
		elif line.begins_with(NEW_SPIRIT):
			spirit_to_give = str(line.right(-NEW_SPIRIT.length()))
		elif line.begins_with(NEW_SILVER):
			silver_to_give = int(line.right(-NEW_SILVER.length()))
		elif line.begins_with(NEW_SOUND):
			sound_to_set = load("res://sounds/%s.ogg" % line.right(-NEW_SOUND.length()))
		elif line.begins_with(NEW_PORTRAIT_SCALE):
			var arr := line.right(-NEW_PORTRAIT_SCALE.length()).split(",")
			portrait_scale_to_set = Vector2(float(arr[0]), float(arr[1]))
	if i >= split.size() - 1:
		dialogue_dictionary[dial.name] = dial
	print("parsing took %s ms" % [((Time.get_ticks_usec() - time) * 0.001)])
	return dialogue_dictionary

