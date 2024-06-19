extends InteractionArea

signal quest_started(q: ForestQuest)

var level := 1.0
@export var available_quests := []:
	get:
		return DAT.get_data("forest_available_quests", [])


func interacted() -> void:
	super()
	_generate_quests()
	SOL.dialogue("quest_board")
	SOL.dialogue_closed.connect(_choosed, CONNECT_ONE_SHOT)


func _generate_quests() -> void:
	if not available_quests.is_empty():
		return
	var quest_names := []
	for i in 3:
		var quest: ForestQuest = ResMan.forest_quests[
				ResMan.forest_quests.keys().pick_random()
				].duplicate()
		if quest.name in quest_names:
			var nr := 2
			if quest.name[quest.name.length() - 1].is_valid_int():
				nr = int(quest.name[quest.name.length() - 1])
				nr += 1
			quest.name = quest.name + " " + str(nr)
		quest_names.append(quest.name)

		var reward := quest.glass_reward
		var comp_times := quest.completion_value
		var reward_ratio := comp_times / float(reward)
		var reward_desired := roundi(randf_range(level + 2, level * 4))
		quest.completion_value = maxi(roundi(reward_ratio * reward_desired), 1)
		quest.glass_reward = reward_desired

		available_quests.append(quest)


func _choosed() -> void:
	match SOL.dialogue_choice:
		&"quests":
			var list: ScrollContainer = SOL.get_node("DialogueBox/DialogueBoxPanel/ScrollContainer")
			list.size = Vector2(80, 35)
			#list.position = Vector2(67, -60)
			var choices := PackedStringArray()
			choices.append("nvm")
			for q in available_quests:
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
			for q: ForestQuest.Active in DAT.get_data("forest_active_quests", []):
				var line := DialogueLine.new()
				line.text = str(q)
				line.choices = ["ok", "cancel"]
				lines.append(line)
			SOL.dialogue_box.adjust_dial("quest_board_active", "lines", lines)
			SOL.dialogue("quest_board_active")
			SOL.dialogue_box.started_speaking.connect(_active_lines)


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
			available_quests.erase(quest)
			quest.start()
			quest_started.emit(quest)
	, CONNECT_ONE_SHOT)


func get_quest_by_name(q_name: String) -> ForestQuest:
	return available_quests.filter(
			func(a):
				return (a as ForestQuest).name == q_name
	)[0]


func _active_lines(line: int) -> void:
	var to_erase := []

