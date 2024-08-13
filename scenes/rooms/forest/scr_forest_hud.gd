extends Control

var forest: ForestPath
@onready var forest_quests: ForestQuesting
@onready var glass_label: Label = $HBoxContainer/GlassCounter/Label
@onready var room_label: Label = $HBoxContainer/RoomCounter/Label
@onready var message_container: MessageContainer = $MessageContainer
@onready var compass_needle: Sprite2D = $HBoxContainer/Compass/Needle
@onready var exp_progress: ProgressBar = $ExpProgress
@onready var current_exp_label: Label = $ExpProgress/CurrentExp
@onready var nextlevel_exp_label: Label = $ExpProgress/NextlevelExp


func forest_ready(_forest: ForestPath) -> void:
	forest = _forest

	get_parent().remove_child(self)
	SOL.add_ui_child(self)
	forest_quests = DAT.get_data("forest_questing")
	if not forest_quests.glass_changed.is_connected(update_glass):
		forest_quests.glass_changed.connect(update_glass)

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
	update_exp_display()


func update_glass() -> void:
	glass_label.text = str(forest_quests.glass)


func update_room() -> void:
	room_label.text = str(forest.current_room + 1)


func update_compass(direction: int) -> void:
	compass_needle.show()
	if direction == ForestGenerator.NORTH:
		compass_needle.rotation_degrees = 0
	elif direction == ForestGenerator.SOUTH:
		compass_needle.rotation_degrees = 180
	elif direction == ForestGenerator.WEST:
		compass_needle.rotation_degrees = 270
	elif direction == ForestGenerator.EAST:
		compass_needle.rotation_degrees = 90
	else:
		compass_needle.hide()


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


func update_exp_display() -> void:
	var greg := ResMan.get_character("greg")
	var split := current_exp_label.text.split("/")
	var old_xp := int(split[0])
	var _old_next := int(split[1])
	var xp := greg.experience
	var next := greg.xp2lvl(greg.level + 1)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	exp_progress.max_value = next
	tw.tween_method(func(a: float):
		current_exp_label.text = str(int(a)) + "/" + str(next)
	, old_xp, xp, 0.5)
	tw.parallel().tween_property(exp_progress, "value", xp, 0.5)
	nextlevel_exp_label.text = "lvl " + str(greg.level)

