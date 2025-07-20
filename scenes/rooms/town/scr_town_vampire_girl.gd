extends Node2D

const CYCLE := 180
const INTERACTED := &"vampire_girl_interaction"
const INTERACTIONS := &"girl_interactions"
const POSITION := &"vampire_girl_position_index"
const GUY_FOLLOW := &"uguy_following"
const VAMP_FOUGHT := &"vampire_fought"

var imminence: int = 0
var bad_condition := false
var girl_inters: int:
	get:
		return DAT.get_data(INTERACTIONS, 0)
	set(to):
		DAT.set_data(INTERACTIONS, to)
var girl_is_intered: bool:
	get:
		return DAT.get_data(INTERACTED, false)
	set(to):
		DAT.set_data(INTERACTED, to)

var player_dir_timer: Timer

@onready var gg_pos: Node2D = $GGPos
@onready var girl := $GGPos/Girl as OverworldCharacter
@onready var uguy := $GGPos/Guy as OverworldCharacter
@onready var greg := $"../../Greg" as PlayerOverworld
@onready var thug_spawners := $"../../Areas".find_children("ThugSpawner*")
@onready var animal_spawners := $"../../Areas".find_children("AnimalSpawner*")
@onready var campsite_area: Area2D = $CampsiteArea


func _ready() -> void:
	var level := ResMan.get_character("greg").level
	if level < 40 or level >= 50 or DAT.get_data(VAMP_FOUGHT, false):
		bad_condition = true
		DAT.set_data(GUY_FOLLOW, false)
		queue_free()
		#print("v: girl not spawned, bad level/fought")
		return

	if DAT.get_data(GUY_FOLLOW, false) and LTS.gate_id != &"vampire_cutscene":
		#print("v: uguy follows")
		uguy_follow()
		return

	if girl_inters > 2:
		girl.queue_free()
		uguy.inspected.connect(_on_uguy_interacted)
		uguy.default_lines.append("uguy_lost")
		#print("v: find girl")
		return

	imminence = level - 40
	if DAT.seconds % CYCLE > maxi((imminence + 1) * 30, CYCLE):
		bad_condition = true
		queue_free()
		girl_is_intered = false
		#print("v: girl not spawned (bad time)")
		return
	girl.inspected.connect(_on_girl_interaction)
	match girl_inters:
		0:
			girl.default_lines.append("girl_" + str(randi_range(1, 5)))
		1:
			girl.default_lines.append("girl_follow")
	uguy.default_lines.append("uguy_" + str(randi_range(1, 4)))
	if not girl_is_intered and (LTS.gate_id != LTS.GATE_LOADING):
		DAT.set_data(POSITION, gg_pos.global_position)
	else:
		gg_pos.global_position = DAT.get_data(POSITION, gg_pos.global_position)
	#print("v: girl spawned at ", gg_pos.global_position)


# note that interacted signal is called before the npc's dialogue logic is ran.
func _on_girl_interaction() -> void:
	uguy.direct_walking_animation(girl.global_position - uguy.global_position)
	if not DAT.get_data(INTERACTED, false):
		girl_inters += 1
	girl_is_intered = true
	if girl_inters == 3:
		_girl_angry_cutscene()
		girl_inters += 1
		return
	if girl.default_lines.is_empty():
		return
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
		if DAT.player_capturers.is_empty():
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


func _girl_angry_cutscene() -> void:
	var cam: Camera2D = $"../../Greg/Camera"
	var vamp_color: ColorContainer = $"../../CanvasModulateGroup/VampColor"
	DAT.capture_player("cutscene")
	var tw := create_tween()
	tw.tween_property(SND.current_song_player, "pitch_scale", 0.55, 1.0)
	tw.parallel().tween_property(cam, "zoom", Vector2(2, 2), 1.0)
	tw.parallel().tween_property(vamp_color, "color", Color.FIREBRICK, 1.0)
	tw.finished.connect(func():
		SOL.dialogue("girl_angry")
		await SOL.dialogue_closed
		tw = create_tween()
		tw.tween_property(SND.current_song_player, "pitch_scale", 1.0, 1.0)
		tw.parallel().tween_property(cam, "zoom", Vector2.ONE, 1.0)
		tw.parallel().tween_property(vamp_color, "color", Color.WHITE, 1.0)
		uguy.default_lines.clear()
		uguy.default_lines.append("uguy_confused")
		await tw.finished
		DAT.free_player("cutscene")
	)


func _save_me() -> void:
	if LTS.gate_id != LTS.GATE_LOADING:
		girl_is_intered = false
