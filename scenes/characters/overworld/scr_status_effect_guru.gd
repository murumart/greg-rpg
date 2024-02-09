extends OverworldCharacter


func interacted() -> void:
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
	for eff in DAT.get_data("known_status_effects", []):
		var eff_name = eff.replace("_", " ")
		newchoices.append(eff_name)
	SOL.dialogue_box.adjust("effect_guru", 0, "choices", newchoices)
	list.size = Vector2(80, 60)
	list.position = Vector2(67, -60)
	SOL.dialogue("effect_guru")
	SOL.dialogue_closed.connect(func():
		list.size = Vector2(40, 35)
		list.position = Vector2(98, -35)
		if SOL.dialogue_choice == "bye":
			return
		var id := SOL.dialogue_choice.replace(" ", "_")
		var dial_id = "stefde_" + id
		if not dial_id in SOL.dialogue_box.dialogues_dict:
			if dial_id.ends_with("immunity"):
				SOL.dialogue_box.dial_concat("stefde_default_immunity", 0,
					[SOL.dialogue_choice.trim_suffix(" immunity")])
				SOL.dialogue("stefde_default_immunity")
				return
			SOL.dialogue("stefde_default")
			return
		SOL.dialogue(dial_id)
	, CONNECT_ONE_SHOT)
	super()
