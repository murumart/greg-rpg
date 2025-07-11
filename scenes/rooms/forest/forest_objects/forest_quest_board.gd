@tool
extends InteractionArea

var level := 1.0
var questing: ForestQuesting = null


func on_interaction() -> void:
	super()
	if questing.available_quests_generated:
		if questing.available_quests.is_empty():
			SOL.dialogue_box.adjust("quest_board", 3, "choices",
					["active", "leave"])
	else:
		_generate_quests()
	SOL.dialogue("quest_board")
	SOL.dialogue_closed.connect(_choosed, CONNECT_ONE_SHOT)
	# DEBUG
	#for x in 30:
		#_generate_quests()
		#level += 1
		#print(questing.available_quests)
		#print(level, "\n")
		#questing.available_quests.clear()


func _generate_quests() -> void:
	SOL.dialogue_box.adjust("quest_board", 3, "choices",
			["quests", "active", "leave"])
	var quest_names := {}
	var tries := 0
	var quests := ResMan.forest_quests
	var weights := quests.values().map(func(a: ForestQuest):
		return a.meta_weight
	)
	while questing.available_quests.size() < 3 or tries > 30:
		tries += 1
		var quest: ForestQuest = Math.weighted_random(quests.values(), weights).duplicate()
		quest_names[quest.name] = quest_names.get(quest.name, 0) + 1
		var special := _quest_generation_special(quest)
		if quest_names[quest.name] > 1:
			if tries < 20:
				continue
			quest.name += " " + str(quest_names[quest.name])
		if not special:
			var reward := quest.glass_reward
			var comp_times := quest.completion_value
			var reward_ratio := comp_times / float(reward)
			#var glass_price := reward / float(comp_times)
			var reward_desired := roundi(randfn(level + 2, level * 0.1))
			quest.completion_value = maxi(floori(reward_ratio * reward_desired), 1)
			quest.glass_reward = maxi(reward_desired, reward)
		questing.available_quests.append(quest)
		questing.available_quests_generated = true


func _choosed() -> void:
	match SOL.dialogue_choice:
		&"quests":
			var list: ScrollContainer = SOL.get_node(
					"DialogueBox/DialogueBoxPanel/ScrollContainer")
			list.size = Vector2(80, 35)
			#list.position = Vector2(67, -60)
			var choices := PackedStringArray()
			choices.append("nvm")
			for q in questing.available_quests:
				choices.append(q.name)
			SOL.dialogue_box.adjust("quest_board_available_quests",
					0, "choices", choices)
			SOL.dialogue("quest_board_available_quests")
			SOL.dialogue_closed.connect(_chose_quest_display, CONNECT_ONE_SHOT)
		&"active":
			var lines: Array[DialogueLine] = []
			var start_line := DialogueLine.new()
			start_line.text = "these are your active quests:"
			lines.append(start_line)
			if questing.active_quests.is_empty():
				SOL.dialogue("quest_board_active_empty")
				return
			for q: ForestQuest.Active in questing.active_quests:
				if not q:
					continue
				var line := DialogueLine.new()
				line.text = str(q)
				line.choices = ["ok", "cancel"]
				lines.append(line)
			SOL.dialogue_box.adjust_dial("quest_board_active", "lines", lines)
			SOL.dialogue("quest_board_active")
			SOL.dialogue_box.finished_speaking.connect(_active_line_finished)
			SOL.dialogue_closed.connect(func():
				var dbox := SOL.dialogue_box as DialogueBox
				if dbox.finished_speaking.is_connected(self._active_line_finished):
					dbox.finished_speaking.disconnect(self._active_line_finished)
			, CONNECT_ONE_SHOT)


func _chose_quest_display() -> void:
	var list: ScrollContainer = SOL.get_node("DialogueBox/DialogueBoxPanel/ScrollContainer")
	list.size = Vector2(40, 35)
	#list.position = Vector2(98, -35)
	if SOL.dialogue_choice == &"nvm":
		return
	var quest := get_quest_by_name(SOL.dialogue_choice)
	SOL.dialogue_box.dial_concat(
			"quest_details", 0,
			[str(quest)])
	SOL.dialogue("quest_details")
	SOL.dialogue_closed.connect(func():
		if SOL.dialogue_choice == &"yes":
			questing.start_quest(quest)
		elif SOL.dialogue_choice == &"no":
			SOL.dialogue_choice = &"quests"
			_choosed()
	, CONNECT_ONE_SHOT)


func get_quest_by_name(q_name: String) -> ForestQuest:
	return questing.available_quests.filter(
			func(a):
				return (a as ForestQuest).name == q_name
	)[0]


func _active_line_finished(line: int) -> void:
	if not questing.active_quests.is_empty():
		#print(" --- quest in question: " + str(questing.active_quests[line - 1]))
		if SOL.dialogue_choice == &"cancel":
			questing.active_quests[line - 1] = null # starting at explanatory line 0


func _quest_generation_special(quest: ForestQuest) -> bool:
	match quest.name:
		"detective":
			var item := ForestGenerator.BIN_LOOT.keys().pick_random() as StringName
			quest.data_key += ResMan.get_item(item).name + " in bins"
			quest.set_meta("correct_item", item)
			var rarity: int = (ForestGenerator.BIN_LOOT.values().max()
					- ForestGenerator.BIN_LOOT[item] + 1)
			quest.glass_reward = maxi(ceili(sqrt(rarity)), 1)
			return true
	return false
