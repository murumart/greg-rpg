class_name ForestQuest extends Resource

@export var name := ""
@export var data_key := &""
@export var completion_value: int
@export var glass_reward := 0


static func gen_random_quest() -> ForestQuest:
	var quest := ForestQuest.new()
	quest.name = DIR.load_cat_names().pick_random()

	return quest


func start() -> Active:
	var acc := Active.new(completion_value, data_key, self)
	DAT.appenda("forest_active_quests", acc)
	return acc


func _to_string() -> String:
	return ("quest " + name
			+ "\n" + data_key.replace("_", " ") + ": " + str(completion_value)
			+ "\n" + "reward: " + str(glass_reward) + " glass")


class Active:

	var completion_value: int
	var data_key := &""
	var quest_reference: ForestQuest


	func _init(
			_completion_value: Variant,
			_data_key: StringName,
			_quest_reference: ForestQuest) -> void:
		completion_value = _completion_value + DAT.get_data(_data_key, 0)
		data_key = _data_key
		quest_reference = _quest_reference


	func get_remaining() -> int:
		return completion_value - DAT.get_data(data_key, 0)


	func check_completion() -> bool:
		if get_remaining() <= 0:
			return true
		return false


	func _to_string() -> String:
		return ("(" + str(get_remaining()) + "/"
				+ str(quest_reference.completion_value)
				+ ") " + str(quest_reference))
