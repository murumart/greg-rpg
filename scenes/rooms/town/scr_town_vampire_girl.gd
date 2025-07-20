extends Node2D

enum Locations {TOWN_PARK, GAMER, STORE, POST}

const INTERACTIONS := &"girl_interactions"
const VISITS := &"girl_visits"
const GUY_FOLLOW := &"uguy_following"
const VAMP_FOUGHT := &"vampire_fought"

var imminence: int = 0
var bad_condition := false
var girl_inters: int:
	get: return DAT.get_data(INTERACTIONS, 0)
	set(to): DAT.set_data(INTERACTIONS, to)
var girl_visits: PackedByteArray:
	get: return DAT.get_data(VISITS, [])
	set(to): DAT.set_data(VISITS, to)

var player_dir_timer: Timer

@onready var girl := $Girl as OverworldCharacter
@onready var uguy := $Guy as OverworldCharacter
@export var greg: PlayerOverworld
@export var camera: Camera2D
@export var location: Locations
@onready var thug_spawners := LTS.get_current_scene().find_children("ThugSpawner*")
@onready var animal_spawners := LTS.get_current_scene().find_children("AnimalSpawner*")
@onready var cutscene_enter_rea: Area2D = $TransformKiller_____/CutsceneEnterRea


func _ready() -> void:
	if not Math.inrange(ResMan.get_character("greg").level, 40, 49) or DAT.get_data(VAMP_FOUGHT, false):
		queue_free()
		return
	if location == Locations.TOWN_PARK:
		position = Vector2(9999, 9999)
		cutscene_enter_rea.body_entered.connect(func(_a) -> void:
			girl_visits.append(location)
			if girl_inters <= 0:
				park_cutscene()
		)
	elif location == Locations.GAMER:
		if girl_inters <= 0:
			queue_free()
			return
		SND.play_song.call_deferred("sweet_girls", 1.0, {play_from_beginning = true})
		var gamer: OverworldCharacter = $"../Guy"
		gamer.default_lines = ["gamer_girl_gamer"]
		if not location in girl_visits:
			girl_inters += 1
			girl_visits.append(location)


func park_cutscene() -> void:
	girl_inters += 1
	position = Vector2(37, 5)
	DAT.capture_player("cutscene")
	SND.play_song("sweet_girls")
	var gpos := global_position - Vector2(16, 0)
	girl.speed = 9000
	uguy.speed = 8000
	uguy.global_position.x = greg.global_position.x + 90
	girl.global_position.x = greg.global_position.x + 90
	girl.move_to(gpos)
	uguy.move_to(gpos + Vector2(20, 0))
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(camera, ^"global_position", global_position + Vector2(0, -16), 1.5)
	await tw.finished
	girl.enter_a_state_of_conversation()
	greg.raycast.target_position = greg.global_position.direction_to(global_position)
	greg.direct_animation()
	var dlg := DialogueBuilder.new().set_char("vampire_talk")
	dlg.add_line(dlg.ml("what a lovely town, innit...?"))
	dlg.add_line(dlg.ml("so little's changed since i was here last...").scallback(func() -> void:
		girl.set_physics_process(false)
		girl.animated_sprite.speed_scale = 1.0
		girl.animated_sprite.play("gleeful")
	))
	dlg.add_line(dlg.ml("hey! i'm just walkin this girl around.").scharacter("uguy").scallback(func() -> void:
		girl.set_physics_process(true)
		girl.direct_walking_animation(Vector2.UP)
		uguy.direct_walking_animation(uguy.global_position.direction_to(greg.global_position))
	))
	dlg.add_line(dlg.ml("carryin 'er luggage."))
	dlg.add_line(dlg.ml("'s excitin when new people show up!"))
	dlg.add_line(dlg.ml("ah! so much to see!").scharacter("vampire_talk").scallback(func() -> void:
		girl.direct_walking_animation(Vector2.DOWN)
		uguy.direct_walking_animation(uguy.global_position.direction_to(girl.global_position))
	))
	dlg.add_line(dlg.ml("i simply must visit all the interesting places in town!"))
	dlg.add_line(dlg.ml("i'm off this way! i heard there's a gamer there!").scallback(func() -> void:
		girl.direct_walking_animation(Vector2.UP)
	))
	await dlg.speak_choice()
	girl.move_to(gpos - Vector2(68, 15))
	girl.target_reached.connect(girl.move_to.call_deferred.bind(girl.global_position - Vector2(0, 90)), CONNECT_ONE_SHOT)
	tw = create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(camera, ^"global_position", greg.global_position.lerp(uguy.global_position, 0.5).floor(), 2.0)
	await tw.finished
	SND.play_song("", 0.8)
	dlg.reset().set_char("uguy")
	dlg.add_line(dlg.ml("to be quite frank with ya...").scallback(func() -> void:
		uguy.direct_walking_animation(uguy.global_position.direction_to(greg.global_position))
	))
	dlg.add_line(dlg.ml("i don't fully trust 'er, that girl."))
	dlg.add_line(dlg.ml("quite suspicious of 'er to just show up now, isn't it...?"))
	dlg.add_line(dlg.ml("with the talk of a vampire in town..."))
	dlg.add_line(dlg.ml("i hope she's not in trouble with him!").scallback(func() -> void:
		uguy.direct_walking_animation(uguy.global_position.direction_to(greg.global_position))
	))
	dlg.add_line(dlg.ml("oi luggage bloke! you coming?").scharacter("vampire_talk").scallback(func() -> void:
		uguy.direct_walking_animation(Vector2.UP)
		SND.play_song("sweet_girls")
	))
	dlg.add_line(dlg.ml("right! gotta go! see ya!").scharacter("uguy").scallback(func() -> void:
		uguy.direct_walking_animation(uguy.global_position.direction_to(greg.global_position))
	))
	await dlg.speak_choice()
	SND.play_song("dry_summer")
	uguy.move_to(gpos - Vector2(68, 15))
	uguy.target_reached.connect(uguy.move_to.call_deferred.bind(uguy.global_position - Vector2(0, 90)), CONNECT_ONE_SHOT)
	tw = create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(camera, ^"position", Vector2(0, -9), 2.0)
	await tw.finished
	uguy.queue_free()
	girl.queue_free()
	DAT.free_player("cutscene")


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
	#campsite_area.body_entered.connect(func(body: Node2D):
		#if body != greg or not DAT.get_data(GUY_FOLLOW, false):
			#return
		#LTS.gate_id = &"vampire_cutscene"
		#LTS.level_transition("res://scenes/rooms/scn_room_town.tscn")
	#)


func _on_uguy_cannot_reach_target() -> void:
	if not DAT.get_data(GUY_FOLLOW, false):
		return
	var tw := create_tween()
	SND.play_sound(preload("res://sounds/teleport.ogg"), {"pitch_scale": randf_range(0.9, 1.2)})
	tw.tween_property(uguy, "global_position", greg.global_position, 0.1)
