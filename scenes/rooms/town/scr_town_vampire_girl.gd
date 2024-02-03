extends Node2D

const CYCLE := 180
const INTERACTED := &"vampire_girl_interaction"
const INTERACTIONS := &"girl_interactions"
const POSITION := &"vampire_girl_position_index"
const GUY_FOLLOW := &"uguy_following"
const VAMP_FOUGHT := &"vampire_fought"

var imminence: int = 0
var bad_condition := false

var player_dir_timer: Timer

@onready var gg_pos: Node2D = $GGPos
@onready var girl := $GGPos/Girl as OverworldCharacter
@onready var uguy := $GGPos/Guy as OverworldCharacter
@onready var position_markers: Node2D = $PositionMarkers
@onready var greg := $"../../Greg" as PlayerOverworld
@onready var thug_spawners := $"../../Areas".find_children("ThugSpawner*")
@onready var animal_spawners := $"../../Areas".find_children("AnimalSpawner*")
@onready var campsite_area: Area2D = $CampsiteArea


func _ready() -> void:
	var level := DAT.get_character("greg").level
	if level < 40 or level >= 50 or DAT.get_data(VAMP_FOUGHT, false):
		bad_condition = true
		DAT.set_data(GUY_FOLLOW, false)
		queue_free()
		return

	if DAT.get_data(GUY_FOLLOW, false) and LTS.gate_id != &"vampire_cutscene":
		uguy_follow()
		return

	if DAT.get_data(INTERACTIONS, 0) > 2:
		girl.queue_free()
		gg_pos.global_position = get_closest_pos()
		uguy.inspected.connect(_on_uguy_interacted)
		uguy.default_lines.append("uguy_lost")
		return

	imminence = level - 40
	if DAT.seconds % CYCLE > maxi((imminence + 1) * 30, CYCLE):
		bad_condition = true
		queue_free()
		DAT.set_data(INTERACTED, false)
		return
	girl.inspected.connect(_on_girl_interaction)
	girl.default_lines.append("girl_" + str(randi_range(1, 5)))
	uguy.default_lines.append("uguy_" + str(randi_range(1, 4)))
	if (not DAT.get_data("interacted", false)) and (LTS.gate_id != LTS.GATE_LOADING):
		gg_pos.global_position = get_rand_pos()
		DAT.set_data(POSITION, gg_pos.global_position)
	else:
		gg_pos.global_position = DAT.get_data(POSITION, gg_pos.global_position)


# note that interacted signal is called before the npc's dialogue logic is ran.
func _on_girl_interaction() -> void:
	uguy.direct_walking_animation(girl.global_position - uguy.global_position)
	if not DAT.get_data(INTERACTED, false):
		DAT.incri(INTERACTIONS, 1)
	DAT.set_data(INTERACTED, true)
	if girl.default_lines.size():
		SOL.dialogue_closed.connect(func():
			girl.default_lines.clear()
		, CONNECT_ONE_SHOT)


func _on_uguy_interacted() -> void:
	SOL.dialogue_closed.connect(func():
		DAT.set_data(GUY_FOLLOW, true)
		uguy_follow()
	, CONNECT_ONE_SHOT)
	uguy.inspected.disconnect(_on_uguy_interacted)


func uguy_follow() -> void:
	player_dir_timer = Timer.new()
	add_child(player_dir_timer)
	player_dir_timer.start(25)
	player_dir_timer.timeout.connect(func():
		SOL.dialogue("uguy_reminder")
	)
	for i in animal_spawners:
		if is_instance_valid(i):
			i.queue_free()
	for i in thug_spawners:
		if is_instance_valid(i):
			i.queue_free()
	uguy.default_lines.clear()
	uguy.default_lines.append("uguy_reminder")
	uguy.cannot_reach_target.connect(_on_uguy_cannot_reach_target)
	uguy.save = true
	uguy.save_position = true
	uguy.chase_target = greg
	uguy._on_detection_area_body_entered(greg) # this is dirty
	uguy.global_position = DAT.get_data(uguy.get_save_key("position"), uguy.global_position)
	campsite_area.body_entered.connect(func(body: Node2D):
		print(body)
		if body != greg or not DAT.get_data(GUY_FOLLOW, false):
			return
		LTS.gate_id = &"vampire_cutscene"
		LTS.level_transition("res://scenes/rooms/scn_room_town.tscn")
	)


func _on_uguy_cannot_reach_target() -> void:
	if not DAT.get_data(GUY_FOLLOW, false):
		return
	var tw := create_tween()
	SND.play_sound(preload("res://sounds/teleport.ogg"), {"pitch_scale": randf_range(0.9, 1.2)})
	tw.tween_property(uguy, "global_position", greg.global_position, 0.1)


func get_rand_pos() -> Vector2:
	return position_markers.get_children().pick_random().global_position


func get_closest_pos() -> Vector2:
	var poses := position_markers.get_children().map(func(node: Node2D): return node.global_position)
	poses.sort_custom(func(a: Vector2, b: Vector2):
		return a.distance_squared_to(greg.global_position) < b.distance_squared_to(greg.global_position))
	return poses[0]


func _save_me() -> void:
	if LTS.gate_id != LTS.GATE_LOADING:
		DAT.set_data(INTERACTED, false)
