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

var active_perks: Array[Perk] = [Perk.new(&"experience_multiplier", 0.5)]


#region QUESTING
func start_quest(quest: ForestQuest) -> void:
	active_quests.append(quest.start())
	quest_started.emit(quest)
	available_quests.clear()


func update_quests() -> void:
	#print(" --- checking quests")
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
	update_room_timed_perks()


func has_quest(quest_name: String) -> bool:
	return active_quests.any(func(a):
		var quest := a as ForestQuest.Active
		return quest.quest_reference.name == quest_name
	)


func _trash_item_got(item: StringName) -> void:
	#print("trash item got ", item)
	var togrant := active_quests.filter(func(a):
		#print(a.get_meta_list())
		return a.quest_reference.get_meta("correct_item", "") == item
	)
	#print(togrant)
	for quest: ForestQuest.Active in togrant:
		quest.complete()
#endregion


#region PERKS
func add_perk(key: StringName, value: float) -> Perk:
	var kp := get_key_perks(key)
	if kp.is_empty():
		var p := Perk.new(key, value)
		active_perks.append(p)
		return p
	else:
		kp[0].amount += value
		return kp[0]
	return null


func get_perk_silver_multiplier() -> float:
	return amount_sum(get_key_perks(&"silver_multiplier_increase"))


func get_perk_item_weight_addition_dictionary() -> Dictionary[StringName, Perk]:
	var dict: Dictionary[StringName, Perk] = {}
	for item: StringName in ForestGenerator.BIN_LOOT.keys():
		var key := &"item_" + item + &"_chance_increase"
		var kp := get_key_perks(key)
		if not kp.is_empty():
			dict[item].amount = amount_sum(kp)
	return dict


func get_perk_extra_trash_amount() -> float:
	return amount_sum(get_key_perks(&"extra_trash"))


func get_perk_tree_reduction() -> float:
	return amount_sum(get_key_perks(&"less_trees"))


func get_perk_enemy_start_damage() -> float:
	return amount_sum(get_key_perks(&"enemy_start_damage"))


func get_perk_experience_multiplier() -> float:
	return amount_sum(get_key_perks(&"experience_multiplier"))
#endregion


func get_key_perks(key: StringName) -> Array[Perk]:
	return active_perks.filter(func(a: Perk) -> bool: return a.name == key)


func amount_sum(perks: Array[Perk]) -> float:
	return perks.reduce(func(accum: float, incr: Perk) -> float: return accum + incr.amount, 0.0)


func grant_glass(amount: int) -> void:
	glass += amount
	SOL.dialogue_box.dial_concat("getglass", 0, [absi(amount)])
	SOL.dialogue("getglass")


func update_room_timed_perks() -> void:
	for i in range(active_perks.size() - 1, -1, -1):
		var d: Perk = active_perks[i]
		d.time_left -= 1
		if d.time_left <= 0:
			active_perks.erase(d)


class Perk:
	var name: StringName
	var time_left := Math.INT_MAX
	var amount: float = 0.0

	func _init(n: StringName, amt: float) -> void:
		name = n
		amount = amt
