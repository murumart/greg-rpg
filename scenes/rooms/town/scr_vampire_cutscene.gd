extends Node2D

const M = preload("res://scenes/vfx/x_menacing.gd")

@onready var cam_pos: Marker2D = $CamPos
@onready var end_pos: Marker2D = $EndPos
@onready var greg_pos: Marker2D = $GregPos
@onready var vamp_pos: Marker2D = $VampPos
@onready var guy_pos: Marker2D = $GuyPos
@onready var camera: Camera2D = $"../../../Greg/Camera"
@onready var uguy: OverworldCharacter = $"../../VampireGirl/Guy"
@onready var greg := $"../../../Greg" as PlayerOverworld
@onready var vampire_girl: OverworldCharacter = $"../../VampireGirl/Girl"
@onready var vampire_sprite: AnimatedSprite2D = $"../../VampireGirl/Girl/GirlSprite"
@onready var cashier := $Cashier as OverworldCharacter
@onready var cashier_sprite: AnimatedSprite2D = $Cashier/CashierSprite
@onready var cashier_hurt_sprite: Sprite2D = $Cashier/HurtSprite
@onready var thug_spawners := $"../../../Areas".find_children("ThugSpawner*")
@onready var animal_spawners := $"../../../Areas".find_children("AnimalSpawner*")

func _ready() -> void:
	await get_tree().process_frame # cutscene greebles are below in the tree
	if LTS.gate_id == &"vampire_cutscene":
		DAT.set_data("uguy_following", false)
		start()
		return
	if LTS.gate_id == LTS.GATE_EXIT_BATTLE and DAT.get_data("vampire_end_cutscene", false):
		DAT.set_data("vampire_end_cutscene", false)
		end()
		return
	queue_free()


func start() -> void:
	end_nuisances()
	show()
	vampire_girl.global_position = vamp_pos.global_position
	uguy.global_position = guy_pos.global_position
	DAT.capture_player("cutscene")
	SOL.dialogue_low_position()
	SND.call_deferred("play_song", "")
	greg.animate("walk_right")
	uguy.direct_walking_animation(Vector2.RIGHT)
	greg.global_position = greg_pos.global_position
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(camera, "global_position", cam_pos.global_position, 2)
	await tw.step_finished
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
		if line == 2:
			create_tween().tween_property(camera, "global_position", greg.global_position, 1)
		elif line == 5:
			create_tween().tween_property(camera, "global_position", vampire_girl.global_position, 1)
	SOL.dialogue_box.started_speaking.connect(cam_change_during_dial_2_func)
	SOL.dialogue("vampire_cutscene_2")
	var ctw := create_tween()
	ctw.tween_property(cashier, "position:x", cashier.position.x + 60, 28)
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
	SND.play_song("vampire_fight", 0.1, {"pitch_scale": 0.65})
	SOL.dialogue("vampire_cutscene_4")
	await SOL.dialogue_closed
	SND.play_song("", 1000)
	LTS.enter_battle(preload("res://resources/battle_infos/vampire_boss.tres"))


func end() -> void:
	show()
	var menacing: M = $Menacing
	var vamp_color: ColorContainer = $"../../../CanvasModulateGroup/VampColor"
	vampire_girl.global_position = vamp_pos.global_position
	var cashier_ouch: bool = DAT.get_data("is_cashier_dead_during_vampire_battle", false)
	end_nuisances()
	SND.play_song("")
	DAT.capture_player("cutscene")
	uguy.queue_free()
	greg.global_position = greg_pos.global_position
	cashier.global_position = end_pos.global_position
	if cashier_ouch:
		cashier_sprite.hide()
		cashier_hurt_sprite.show()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(1)
	tw.tween_callback(func():
		cashier.direct_walking_animation(Vector2.RIGHT)
		greg.animate("walk_right")
	)
	tw.tween_property(camera, "global_position", cam_pos.global_position, 1.0)
	tw.tween_callback(func():
		SOL.dialogue("vampire_after_battle")
		vampire_girl.direct_walking_animation(Vector2.LEFT)
		SOL.dialogue_closed.connect(func():
			tw.play()
		, CONNECT_ONE_SHOT)
	)
	tw.tween_callback(tw.pause)
	tw.tween_interval(2)
	tw.tween_callback(func():
		cashier.direct_walking_animation(Vector2.RIGHT)
		vampire_girl.set_physics_process(false)
		vampire_girl.animated_sprite.play("old")
		SND.play_sound(preload("res://sounds/biking_snail_crush.ogg"))
	)
	tw.tween_interval(2)
	await tw.finished
	SOL.dialogue("vampire_after_battle_2")
	await SOL.dialogue_closed
	var tw2 := create_tween().set_trans(Tween.TRANS_CUBIC)
	SND.play_sound(preload("res://sounds/men-03.ogg"), {volume = -4})
	tw2.tween_property(vamp_color, ^"color", Color(0.074, 0.441, 0.169), 1.2)
	SND.play_song("bymssc", 10)
	#SOL.vfx("overrun", camera.to_local(vampire_girl.global_position) + Vector2(0, -10))
	var snd := SND.play_sound(preload("res://sounds/men-01.ogg"))
	tw2.set_ease(Tween.EASE_OUT).tween_property(menacing, ^"global_position", vampire_girl.global_position, 0.5)
	tw2.tween_callback(func() -> void:
		cashier.direct_walking_animation(Vector2.RIGHT)
		SND.play_song("", 999)
		snd.stop()
		menacing.particles(1.0)
	)
	tw2.tween_interval(0.2)
	tw2.tween_callback(func() -> void:
		cashier.direct_walking_animation(Vector2.RIGHT)
		SND.play_song("bymssc", 10)
		SND.play_sound(preload("res://sounds/men-02.ogg"))
		tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(cashier, ^"global_position:x", cashier.global_position.x - 12, 0.2)
	)
	#SOL.vfx("explosion", camera.to_local(vampire_girl.global_position), {"scale": Vector2(0.3, 0.3)})
	tw2.tween_property(vampire_girl, "global_position", Vector2(500, vampire_girl.global_position.y - 60), 0.3)
	tw2.parallel().tween_property(menacing, "global_position", Vector2(500, vampire_girl.global_position.y - 60), 0.3)
	tw2.parallel().tween_callback(SND.play_song.bind("", 0.1))
	tw2.tween_property(vamp_color, ^"color", Color(0.811, 1.0, 0.884), 4.0)
	await tw2.finished
	SOL.dialogue("vampire_after_battle_3")
	SND.play_song("bymssc", 0.5, {volume = -8})
	await SOL.dialogue_closed
	tw = create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(camera, "global_position", greg.global_position, 3.0 + int(cashier_ouch) * 10.0)
	tw.parallel().tween_property(vamp_color, ^"color", Color.WHITE, 3.0)
	if cashier_ouch:
		cashier_hurt_sprite.hide()
		cashier_sprite.show()
		cashier.speed = 900
	cashier.move_to(Vector2(347, -465))
	cashier.target_reached.connect(func():
		cashier.move_to(cashier.global_position + Vector2(300, 0))
	, CONNECT_DEFERRED)
	await tw.finished
	DAT.free_player("cutscene")
	LTS.gate_id = LTS.GATE_EXIT_CUTSCENE
	LTS.level_transition("res://scenes/rooms/scn_room_town.tscn")


func end_nuisances() -> void:
	for i in thug_spawners:
		i.queue_free()
	for j in animal_spawners:
		j.queue_free()
