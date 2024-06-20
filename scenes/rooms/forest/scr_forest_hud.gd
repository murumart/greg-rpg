extends Control

var forest: ForestPath
@onready var forest_quests: ForestQuesting
@onready var glass_label: Label = $HBoxContainer/GlassCounter/Label
@onready var room_label: Label = $HBoxContainer/RoomCounter/Label
@onready var message_container: MessageContainer = $MessageContainer


func forest_ready(_forest: ForestPath) -> void:
	forest = _forest

	get_parent().remove_child(self)
	SOL.add_ui_child(self)
	forest_quests = DAT.get_data("forest_questing")

	forest_quests.quest_started.connect(func(q: ForestQuest):
		message("started quest " + q.name)
	)
	forest_quests.quest_completed.connect(func(q: ForestQuest.Active):
		update_glass()
		message("completed quest " + q.quest_reference.name,
				{quest_complete = true})
	)
	update_glass()
	update_room()


func update_glass() -> void:
	glass_label.text = str(forest_quests.glass)


func update_room() -> void:
	room_label.text = str(forest.current_room + 1)


var _msg_sound_played := false
func message(text: String, options := {}) -> void:
	message_container.push_message(text, options)
	if _msg_sound_played:
		return
	if options.get("quest_complete", false):
		SND.play_sound(preload("res://sounds/gui/forest_quest.ogg"))
	else:
		SND.play_sound(preload("res://sounds/gui/forest_notif.ogg"))
	_msg_sound_played = true
	set_deferred("_msg_sound_played", false)
