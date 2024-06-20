class_name ForestQuesting

signal quest_started(quest: ForestQuest)
signal quest_completed(quest: ForestQuest.Active)

var glass: int = 0
var available_quests: Array[ForestQuest] = []
var available_quests_generated := false
var active_quests: Array[ForestQuest.Active] = []


func start_quest(quest: ForestQuest) -> void:
	available_quests.erase(quest)
	active_quests.append(quest.start())
	quest_started.emit(quest)


func update_quests() -> void:
	print(" --- checking quests")
	var removing := []
	for q: ForestQuest.Active in active_quests:
		if not q:
			removing.append(q)
			continue
		var completed := q.check_completion()
		if completed:
			removing.append(q)
			glass += q.quest_reference.glass_reward
			quest_completed.emit(q)
	for q in removing:
		active_quests.erase(q)
