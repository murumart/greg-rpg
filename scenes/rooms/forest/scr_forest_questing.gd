class_name ForestQuesting

signal quest_started(quest: ForestQuest)
signal quest_completed(quest: ForestQuest.Active)

signal glass_changed

var glass: int = 0:
	set(to):
		glass = to
		glass_changed.emit()
var available_quests: Array[ForestQuest] = []
var available_quests_generated := false
var active_quests: Array[ForestQuest.Active] = []

var active_perks := {}


#region QUESTING
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


func has_quest(quest_name: String) -> bool:
	return active_quests.any(func(a):
		var quest := a as ForestQuest.Active
		return quest.quest_reference.name == quest_name
	)


func _trash_item_got(item: StringName) -> void:
	var togrant := active_quests.filter(func(a):
		return a.get_meta("correct_item", "") == item
	)
	for quest: ForestQuest.Active in togrant:
		quest.complete()
#endregion


#region PERKS
func add_perk(perk: Dictionary) -> void:
	for key in perk.keys():
		var value: float = perk[key]
		if not active_perks.has(key):
			active_perks[key] = value
			continue
		active_perks[key] += value


func get_perk_silver_multiplier() -> float:
	return active_perks.get("silver_multiplier_increase", 1.0)


func get_perk_item_weight_addition_dictionary() -> Dictionary:
	var dict := {}
	for item: StringName in ForestGenerator.BIN_LOOT.keys():
		var key := "item_" + item + "_chance_increase"
		if active_perks.has(key):
			if not dict.has(item):
				dict[item] = 0.0
			dict[item] += active_perks[key]
	return dict


func get_perk_extra_trash_amount() -> int:
	return roundi(active_perks.get("extra_trash", 0.0))


func get_perk_tree_reduction() -> int:
	return roundi(active_perks.get("less_trees", 0.0))
#endregion
