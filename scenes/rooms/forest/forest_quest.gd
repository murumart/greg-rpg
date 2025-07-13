class_name ForestQuest extends Resource

@export var name := ""
@export_multiline var description := ""
@export var data_key := &""
@export var completion_value: int
@export var completion_signal := &""
@export var glass_reward := 0

@export var meta_weight := 100


func start() -> Active:
	var acc := Active.new(self)
	return acc


func get_long_description() -> String:
	return (description + "\n"
		+ data_key.replace("_", " ") + ": " + str(completion_value)
		+ "\n" + "reward: " + str(glass_reward) + " glass")


func _to_string() -> String:
	return ("quest " + name
			+ "\n" + data_key.replace("_", " ") + ": " + str(completion_value)
			+ "\n" + "reward: " + str(glass_reward) + " glass")


class Active:

	var completion_value: int
	var data_key := &""
	var quest_reference: ForestQuest
	var _completed := false # set by signal


	func _init(_quest_reference: ForestQuest) -> void:
		data_key = _quest_reference.data_key
		completion_value = _quest_reference.completion_value + DAT.get_data(data_key, 0)
		quest_reference = _quest_reference
		var questing := DAT.get_data("forest_questing", null) as ForestQuesting
		if questing and quest_reference.completion_signal:
			connect(quest_reference.completion_signal,
				func():
					_completed = true
					questing.update_quests()
					, CONNECT_ONE_SHOT)


	func get_remaining() -> int:
		return completion_value - DAT.get_data(data_key, 0)


	func check_completion() -> bool:
		if _completed or get_remaining() <= 0:
			return true
		return false


	func complete() -> void:
		_completed = true


	func _to_string() -> String:
		return ("(" + str(quest_reference.completion_value - get_remaining())
				+ "/" + str(quest_reference.completion_value)
				+ ") ") + str(quest_reference)
