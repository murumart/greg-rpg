extends Node2D

const LPOS := -41

@onready var camera_area: Area2D = $CameraArea
@onready var ladder: Sprite2D = $Ladder
@onready var ladder_place: InteractionArea = $LadderPlace
@onready var climbing_place := $ClimbingPlace
@onready var broken_window: Sprite2D = $BrokenWindow
@onready var climb_target: Area2D = $ClimbTarget
@onready var greg_climp: Node2D = $ClimbingPlace/GregClimp
@onready var atgirl: OverworldCharacter = $Atgirl

@export var cam: Camera2D
@export var greg: PlayerOverworld

var cam_pan_time := 0.75
var ladder_active: bool:
	set(to): DAT.set_data("mayor_ladder_actieve", to)
	get: return DAT.get_data("mayor_ladder_actieve", false)
var window_broken: bool:
	set(to): DAT.set_data("mayor_window_broken", to)
	get: return DAT.get_data("mayor_window_broken", false)
var climping := false
var room_entered := false


func _ready() -> void:
	room_entered = &"mayor_apartment" in DAT.get_data("visited_rooms", [])
	if room_entered:
		climbing_place.greg_speed = 60.0
	camera_area.body_entered.connect(_cam_in.unbind(1))
	camera_area.body_exited.connect(_cam_out.unbind(1))
	ladder_place.interacted.connect(_ladder_interacted)
	climbing_place.started_falling.connect(func() -> void: climping = false; ladder.position.x = LPOS)
	climbing_place.stopped_climbing.connect(func() -> void: climping = false; ladder.position.x = LPOS)
	climb_target.area_entered.connect(_target_reached.unbind(1))
	_ladder_display()
	if LTS.gate_id == &"town-mayor":
		climping = true
		greg.global_position = Vector2(climb_target.global_position.x, climbing_place.ground_level_y)
		climbing_place.begin_climping()
		greg_climp.global_position = climb_target.global_position + Vector2(0, 12)


var t := 0.0
func _physics_process(delta: float) -> void:
	t += delta
	if not climping or room_entered:
		return
	var add := sin(t * 1.76) * 14.0
	ladder.position.x = LPOS + add


func _ladder_display() -> void:
	ladder.visible = ladder_active
	broken_window.visible = window_broken
	if ladder_active:
		atgirl.default_lines = [&"atgirl_what"]


func _ladder_interacted() -> void:
	var g := ResMan.get_character("greg")
	if not ladder_active and &"ladder" in g.inventory:
		ladder_active = true
		g.inventory.erase(&"ladder")
		_ladder_display()
		SND.play_sound(preload("res://sounds/use_item.ogg"))
		SOL.dialogue("ladder_added")
	elif ladder_active:
		print("you ladder.")
		climbing_place.begin_climping()
		climping = true
		t = 0.0


func _target_reached() -> void:
	if climbing_place.state != climbing_place.States.CLIMBING:
		return
	if not window_broken:
		window_broken = true
		room_entered = true # cancel ladder moving
		_ladder_display()
		climbing_place.state = climbing_place.States.HALTED
		if is_instance_valid(SND.current_song_player):
			SND.current_song_player.volume_db = -80
		await SND.play_sound(preload("res://sounds/glass_break_long.ogg")).finished
		if is_instance_valid(SND.current_song_player):
			SND.current_song_player.volume_db = 0
	LTS.gate_id = &"town-mayor"
	LTS.level_transition("res://scenes/rooms/scn_room_mayor_apartment.tscn")
	DAT.free_player("climp")


func _cam_in() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(cam, ^"global_position:y", global_position.y + 28, cam_pan_time)


func _cam_out() -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(cam, ^"position:y", -9, cam_pan_time)
