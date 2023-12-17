extends Node2D

@onready var guru: OverworldCharacter = $StatusEffectGuru
@onready var tarikas: OverworldCharacter = $Tarikas


func _ready() -> void:
	tarikas.inspected.connect(_on_tarikas_inspected)
	tarikas_lines()
	guru.inspected.connect(_on_guru_inspected)
	if DAT.get_data("battles", 0) < 2:
		guru.queue_free()


func _on_guru_inspected() -> void:
	var list: ScrollContainer = SOL.get_node("DialogueBoxOrderer/DialogueBoxPanel/ScrollContainer")
	if not DAT.get_data("talked_to_guru", false):
		DAT.set_data("talked_to_guru", true)
		SOL.dialogue("effect_guru_hi")
		return
	if DAT.get_data("known_status_effects", []).size() < 1:
		SOL.dialogue("effect_guru_noeffects")
		return
	var newchoices := PackedStringArray()
	newchoices.append("bye")
	var newlines: Array[DialogueLine] = []
	for eff in DAT.get_data("known_status_effects", []):
		var eff_name = eff.replace("_", " ")
		newchoices.append(eff_name)
		var newline := DialogueLine.new()
		newline.choice_link = StringName(eff_name)
		newline.text = StatusEffect.DESCRIPTIONS.get(
			eff, StatusEffect.DESCRIPTIONS.default)
		if "_immunity" in eff:
			if not eff in StatusEffect.DESCRIPTIONS:
				newline.text = StatusEffect.DESCRIPTIONS.default_immunity % eff_name
		newline.loop = 0
		newlines.append(newline)
		
	SOL.dialogue_box.adjust("effect_guru", 0, "choices", newchoices)
	SOL.dialogue_box.dialogues_dict.effect_guru.lines.resize(2)
	SOL.dialogue_box.dialogues_dict.effect_guru.lines.append_array(newlines)
	list.size.y = 60
	SOL.dialogue("effect_guru")
	SOL.dialogue_closed.connect(func(): list.size.y = 35, CONNECT_ONE_SHOT)


func tarikas_lines() -> void:
	var level := DAT.get_character("greg").level
	var lines_to_set: Array[StringName] = []
	tarikas.convo_progress = 0
	if not DAT.get_data("tarikas_talked_to", false):
		lines_to_set.append("tarikas_hello")
	if level < 5:
		pass
	elif Math.inrange(level, 6, 10):
		lines_to_set.append("tarikas_10")
	elif Math.inrange(level, 11, 15):
		lines_to_set.append("tarikas_15")
	elif Math.inrange(level, 16, 25):
		if DAT.get_data("biking_games_finished", 0) > 0:
			lines_to_set.append("tarikas_25")
	elif Math.inrange(level, 26, 35):
		lines_to_set.append("tarikas_30")
	elif level == 36:
		lines_to_set.append("tarikas_36")
	elif Math.inrange(level, 37, 49):
		if DAT.get_data("fulfilled_bounty_thugs", false):
			lines_to_set.append("tarikas_40_nothugs")
		else:
			if DAT.get_data("met_tarikas_beyond_lake", false):
				lines_to_set.append("tarikas_40_met")
			else:
				lines_to_set.append("tarikas_40_nomeet")
	elif Math.inrange(level, 50, 59):
		lines_to_set.append("tarikas_50")
	lines_to_set.append("tarikas_finish")
	tarikas.default_lines = lines_to_set

func _on_tarikas_inspected() -> void:
	DAT.set_data("tarikas_talked_to", true)

