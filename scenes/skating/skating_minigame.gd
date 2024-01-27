extends Node2D

const CameraType := preload("res://scenes/tech/scr_camera.gd")
const PlayerType := preload("res://scenes/skating/player.gd")
const UIType := preload("res://scenes/skating/ui.gd")

var points := 0

var camera_timer := Timer.new()
var jumpscare_timer := Timer.new()
@onready var ui := $UI as UIType
@onready var camera := $MainCamera as CameraType
@onready var player := $Player as PlayerType
@onready var jumpscare_sprite: Sprite2D = $UI/Jumpscare


func _ready() -> void:
	remove_child(ui)
	SOL.add_ui_child(ui)
	add_child(camera_timer)
	camera_timer.start(1)
	camera_timer.timeout.connect(_camera_timeout)
	add_child(jumpscare_timer)
	jumpscare_timer.start(randf_range(30, 60))
	jumpscare_timer.timeout.connect(jumpscare)
	camera.make_current()
	player.broadcast_balance.connect(ui.display_balance)
	player.broadcast_boredom.connect(ui.display_boredom)
	player.did_trick.connect(ui.add_points)
	player.game_over.connect(end)
	SND.play_song("best")


func _camera_timeout() -> void:
	camera.make_current()
	camera_timer.start(randf_range(1.0, 10.0))
	if is_instance_valid(SND.current_song_player):
		var tw := create_tween()
		tw.tween_property(SND.current_song_player, "pitch_scale",
				maxf(SND.current_song_player.pitch_scale + randf_range(-0.1, 0.1), 0.1), randf_range(1, 4))


func jumpscare() -> void:
	jumpscare_sprite.region_rect.position.x = 0
	var tw := create_tween()
	tw.tween_property(jumpscare_sprite, "position:x", 50.0, 0.7).from(-30.0)
	tw.tween_callback(func():
		jumpscare_sprite.region_rect.position.x = 30
		SND.play_sound(preload("res://sounds/skating/jumpscare.ogg"))
	)
	tw.tween_method(
		func(_ö: float):
			var txt = SOL.vfx("damage_number", Vector2(15, 0), 
				{"text": "jumpscare!!!", "color": Color.GRAY, "parent": jumpscare_sprite})
			txt.z_as_relative = false
			txt.z_index -= 1
	, 0.0, 1.0, 1.5)
	tw.tween_callback(func(): jumpscare_sprite.region_rect.position.x = 0)
	tw.tween_property(jumpscare_sprite, "position:x", 160.0, 1)
	jumpscare_timer.start(randf_range(30, 60))


func end() -> void:
	SND.play_song("")
	await create_tween().tween_interval(1).finished
	var rews := BattleRewards.new()
	var reward := Reward.new()
	reward.type = BattleRewards.Types.EXP
	reward.property = str(floori(ui.points * 0.000166667))
	rews.add(reward)
	rews.grant()
	SOL.dialogue_closed.connect(func():
		LTS.gate_id = LTS.GATE_EXIT_GAMING
		LTS.level_transition(LTS.ROOM_SCENE_PATH % DAT.get_data("current_room", "town"))
	, CONNECT_ONE_SHOT)


