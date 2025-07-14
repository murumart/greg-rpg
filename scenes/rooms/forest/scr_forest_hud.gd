extends Control

var forest: ForestPath
@onready var forest_quests: ForestQuesting
@onready var glass_label: Label = %GlassLabel
@onready var room_label: Label = %RoomLabel
@onready var message_container: MessageContainer = %MessageContainer
@onready var compass_needle: Sprite2D = %CompassNeedle
@onready var exp_progress: ProgressBar = %ExpProgress
@onready var current_exp_label: Label = %ExpProgress/CurrentExp
@onready var nextlevel_exp_label: Label = %ExpProgress/NextlevelExp
@onready var health_bar: ProgressBar = $HealthBar

var greeble_storage: Dictionary[TextureRect, Array]
@onready var greebles: HBoxContainer = %Greebles
@onready var question_greeble: TextureRect = %QuestionGreeble
@onready var board_greeble: TextureRect = %BoardGreeble
@onready var trash_greeble: TextureRect = %TrashGreeble
@onready var greenhouse_greeble: TextureRect = %GreenhouseGreeble
@onready var enemy_greeble: TextureRect = %EnemyGreeble
@onready var hazard_greeble: TextureRect = %HazardGreeble


func forest_ready(_forest: ForestPath) -> void:
	forest = _forest

	greebles.remove_child(question_greeble)
	greebles.remove_child(board_greeble)
	greebles.remove_child(trash_greeble)
	greebles.remove_child(greenhouse_greeble)
	greebles.remove_child(enemy_greeble)
	greebles.remove_child(hazard_greeble)

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
	update_greebles_display.call_deferred()
	var tw := create_tween().set_loops()
	tw.tween_interval(1)
	tw.tween_callback(update_exp_display)
	tw.tween_callback(update_greebles_display)
	greeble_storage = {
		question_greeble: [],
		board_greeble: [],
		trash_greeble: [],
		greenhouse_greeble: [],
		enemy_greeble: [],
		hazard_greeble: [],
	}


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


func update_greebles_display() -> void:
	var trash: int = get_tree().get_nodes_in_group("forest_bins").filter(func(b: TrashBin) -> bool:
		return b.full
	).size()
	var curiosities: int = get_tree().get_node_count_in_group("forest_curiosities")
	var board: bool = forest.current_room % ForestGenerator.BOARD_INTERVAL == 0
	var greenhouse: bool = forest.current_room % ForestGenerator.GREENHOUSE_INTERVAL == 0 and forest.current_room >= 2
	var enemies: int = get_tree().get_node_count_in_group("forest_enemies")
	var hazards: int = get_tree().get_node_count_in_group("forest_hazards")

	_right_greeble(question_greeble, curiosities)
	_right_greeble(board_greeble, int(board))
	_right_greeble(trash_greeble, trash)
	_right_greeble(greenhouse_greeble, int(greenhouse))
	_right_greeble(enemy_greeble, enemies)
	_right_greeble(hazard_greeble, hazards)


func _right_greeble(key: TextureRect, amt: int) -> void:
	while amt > greeble_storage[key].size():
		var tg := key.duplicate(0)
		greeble_storage[key].append(tg)
		greebles.add_child(tg)
	while amt < greeble_storage[key].size():
		_fade_greeble(key)


func _fade_greeble(key: TextureRect) -> void:
	var g: TextureRect = greeble_storage[key].front()
	greeble_storage[key].erase(g)
	var tw := g.create_tween()
	tw.tween_property(g, ^"modulate:a", 0.0, 0.1)
	tw.tween_callback(g.queue_free)


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
	health_bar.max_value = greg.max_health
	if health_bar.value == 0: health_bar.value = greg.max_health
	tw.tween_method(func(a: float):
		current_exp_label.text = str(int(a)) + "/" + str(next)
	, old_xp, xp, 0.5)
	tw.parallel().tween_property(exp_progress, ^"value", xp, 0.5)
	tw.parallel().tween_property(health_bar, ^"value", greg.health, 0.5).from(health_bar.value)
	nextlevel_exp_label.text = "lvl " + str(greg.level)
