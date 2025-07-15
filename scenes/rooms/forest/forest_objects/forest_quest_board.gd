@tool
extends InteractionArea

const QuestBoard = preload("res://scenes/gui/scr_bounty_board.gd")

var level := 1.0
var questing: ForestQuesting = null


func on_interaction() -> void:
	super()

	if not DAT.get_data("quest_board_introed", false):
		DAT.set_data("quest_board_introed", true)
		SOL.dialogue("quest_board")
		await SOL.dialogue_closed

	var qb := QuestBoard.make()
	qb.close_requested.connect(func() -> void:
		qb.queue_free()
		DAT.free_player("board")
	)
	DAT.capture_player("board")
	SOL.add_ui_child(qb)

	if not questing.available_quests_generated:
		_generate_quests()

	var quests: Array[QuestBoard.QuestListElement] = []
	if not questing.available_quests.is_empty():
		quests.append(QuestBoard.QuestListElement.new("available"))
		for q in questing.available_quests:
			var qu := QuestBoard.Quest.new(
				q.name, q.get_long_description(),
				0, q.completion_value,
				null, false
			)
			qu.set_meta("quest_object", q)
			quests.append(qu)
	if not questing.active_quests.is_empty():
		quests.append(QuestBoard.QuestListElement.new("active"))
		for q in questing.active_quests:
			quests.append(QuestBoard.Quest.new(
				q.quest_reference.name,
				q.quest_reference.get_long_description(),
				q.quest_reference.completion_value - q.get_remaining(),
				q.quest_reference.completion_value,
				null, true
			))

	qb.quest_activated.connect(func(q: QuestBoard.Quest) -> void:
		questing.start_quest(q.get_meta("quest_object"))
		qb.close_requested.emit()
		#on_interaction.call_deferred()
	)
	qb.fill(quests)


func _generate_quests() -> void:
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
