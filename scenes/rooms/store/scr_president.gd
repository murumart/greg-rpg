extends Node2D

@onready var president := $President as OverworldCharacter
@onready var greg := $"../Greg" as PlayerOverworld
@onready var store: Node2D = $".."
@onready var camera: Camera2D = $"../Greg/Camera"
@onready var canvas_modulate: CanvasModulate = $"../Decor/CanvasModulate"
@onready var greg_poses := [$President/GregPos1, $President/GregPos2]
@onready var milk: Sprite2D = $President/Milk
@onready var clickbait: Sprite2D = $President/Milk/Clickbait
@onready var animation_player: AnimationPlayer = $President/Milk/AnimationPlayer

var song_pitching := true
var rotating := false


func _ready() -> void:
	president.inspected.connect(_president_inspected)


func _physics_process(_delta: float) -> void:
	if is_instance_valid(SND.current_song_player) and song_pitching:
		SND.current_song_player.pitch_scale = minf(remap(president.global_position.distance_to(
				greg.global_position), 0.0, 66.0, 0.75, 1.0), 1.0)


func _president_inspected() -> void:
	song_pitching = false
	president.path_container = null
	president.speed = 0
	president.move_to(president.global_position)
	DAT.capture_player("cutscene")
	greg.animate("walk_down")
	var tw := create_tween()
	if is_instance_valid(SND.current_song_player):
		tw.tween_property(SND.current_song_player, "pitch_scale", 0.001, 1.0)
	tw.parallel().tween_property(camera, "zoom", Math.v2(4.0), 1.0)
	tw.parallel().tween_callback(func():
		SND.play_song(""))
	tw.set_trans(Tween.TRANS_CUBIC)
	greg_poses.sort_custom(
		func(a, b): return a.global_position.distance_to(greg.global_position
			) - b.global_position.distance_to(greg.global_position) < 0.0)
	tw.parallel().tween_property(
			greg,
			"global_position",
			greg_poses[0].global_position,
			1.0)
	tw.parallel().tween_property(camera, "global_position",
			greg.global_position.move_toward(president.global_position, 0.5) - Vector2(0, 10), 1.0)
	tw.parallel().tween_method(func(f): $"../Shelves".get_children().map(func(a):
		a.modulate.a = f), 1.0, 0.0, 1.0)
	tw.parallel().tween_callback(
		func():
		president.direct_walking_animation(
			president.global_position.direction_to(greg_poses[0].global_position)))
	milk.show()
	clickbait.modulate.a = 0.0
	tw.tween_property(clickbait, "modulate:a", 1.0, 1.0)
	tw.tween_interval(0.2)
	tw.tween_callback(animation_player.play.bind("milkfall"))
	animation_player.animation_finished.connect(func(_a):
		tw = create_tween()
		tw.tween_interval(1.0)
		SOL.dialogue("president_bump")
		SOL.dialogue_closed.connect(func():
			SOL.fade_screen(Color.TRANSPARENT, Color.WHITE, 0.1)
			await SOL.fade_finished
			LTS.gate_id = LTS.GATE_ENTER_BATTLE
			LTS.change_scene_to("res://scenes/tech/scn_battle.tscn",
					{"battle_info": preload("res://resources/battle_infos/president_fight.tres")})
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)


func fucked_rotate(amout: float) -> void:
	store.rotate(amout)
	$"../Shelves".get_children().map(func(a):
		a.global_rotation = 0
		a.get_child(1).modulate.a = 0.0
	)
	greg.global_rotation = 0
	president.global_rotation = 0
	$"../Kassa".global_rotation = 0
	$"../Decor".get_children().map(func(a): a.global_rotation = 0)
