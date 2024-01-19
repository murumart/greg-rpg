extends Node2D

@onready var cam_pos: Marker2D = $CamPos
@onready var end_pos: Marker2D = $EndPos
@onready var greg_pos: Marker2D = $GregPos
@onready var camera: Camera2D = $"../../../Greg/Camera"
@onready var uguy := $UGuy as OverworldCharacter
@onready var greg := $"../../../Greg" as PlayerOverworld
@onready var vampire_girl := $VampireGirl as OverworldCharacter
@onready var cashier := $Cashier as OverworldCharacter


func start() -> void:
	SND.play_song("")
	DAT.capture_player("cutscene")
	greg.animate("walk_right")
	uguy.direct_walking_animation(Vector2.RIGHT)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(camera, "global_position", cam_pos.global_position, 2)
	await tw.step_finished
	greg.global_position = greg_pos.global_position
	uguy.move_to(vampire_girl.global_position - Vector2(20, 0))
	await uguy.target_reached
	vampire_girl.direct_walking_animation(Vector2.LEFT)
	SOL.dialogue("vampire_cutscene_1")
	await SOL.dialogue_closed
	var t2 := create_tween().set_trans(Tween.TRANS_CUBIC).set_parallel(true)
	t2.tween_property(uguy, "global_position", uguy.global_position - Vector2(300, 20), 1) 
	t2.tween_property(vampire_girl, "position", vampire_girl.position - Vector2(30, 2), 0.2)
	SOL.vfx("explosion", camera.to_local(uguy.global_position))
	await get_tree().create_timer(1.6).timeout
	SND.play_song("geezer", 0.1, {"start_volume": 0})
	vampire_girl.direct_walking_animation(Vector2.DOWN)
	create_tween().tween_property(camera, "global_position", vampire_girl.global_position, 1)
	await get_tree().create_timer(1.6).timeout
	var cam_change_during_dial_2_func := func(line: int):
		if line == 3:
			create_tween().tween_property(camera, "global_position", greg.global_position, 1)
		elif line == 6:
			create_tween().tween_property(camera, "global_position", vampire_girl.global_position, 1)
	SOL.dialogue_box.started_speaking.connect(cam_change_during_dial_2_func)
	SOL.dialogue("vampire_cutscene_2")
	var ctw := create_tween()
	ctw.tween_property(cashier, "position:x", cashier.position.x + 60, 20)
	await SOL.dialogue_closed
	SOL.dialogue_box.started_speaking.disconnect(cam_change_during_dial_2_func)
	SND.play_song("", 10)
	if ctw.is_running():
		ctw.stop()
	tw = create_tween().set_trans(Tween.TRANS_BOUNCE)
	tw.tween_property(vampire_girl, "position:y", vampire_girl.position.y - 16, 0.1)
	tw.tween_property(vampire_girl, "position:y", vampire_girl.position.y, 0.1)
	await get_tree().create_timer(0.5).timeout
	vampire_girl.direct_walking_animation(Vector2.UP)
	SOL.dialogue("vampire_cutscene_3")
	await SOL.dialogue_closed
	var t3 := create_tween().set_trans(Tween.TRANS_CUBIC)
	t3.tween_callback(vampire_girl.direct_walking_animation.bind(Vector2.UP))
	t3.tween_callback(SND.play_sound.bind(preload("res://sounds/teleport.ogg")))
	t3.tween_property(vampire_girl, "global_position", cashier.global_position, 0.1)
	t3.tween_callback(SND.play_sound.bind(preload("res://sounds/teleport.ogg")))
	t3.tween_property(vampire_girl, "global_position", end_pos.global_position, 0.1)
	t3.parallel().tween_callback(vampire_girl.direct_walking_animation.bind(Vector2.DOWN))
	t3.parallel().tween_callback(cashier.direct_walking_animation.bind(Vector2.DOWN))
	t3.parallel().tween_property(cashier, "global_position", end_pos.global_position, 0.2)
	t3.parallel().tween_property(camera, "global_position", end_pos.global_position, 1)
	t3.tween_callback(vampire_girl.direct_walking_animation.bind(Vector2.RIGHT))
	t3.tween_property(vampire_girl, "global_position:x", end_pos.global_position.x + 16, 0.5)
	t3.tween_callback(vampire_girl.direct_walking_animation.bind(Vector2.DOWN))
	await t3.finished
	SND.play_song("vampire_fight", 0.5, {"pitch_scale": 0.75})
	SOL.dialogue("vampire_cutscene_4")
	await SOL.dialogue_closed
	LTS.enter_battle(preload("res://resources/battle_infos/vampire_boss.tres"))

