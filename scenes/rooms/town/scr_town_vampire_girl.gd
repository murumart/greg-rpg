extends Node2D

enum Locations {TOWN_PARK, GAMER, STORE, POST, POLICE}

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
@export var campsite_area: Area2D
@onready var thug_spawners := LTS.get_current_scene().find_children("ThugSpawner*")
@onready var animal_spawners := LTS.get_current_scene().find_children("AnimalSpawner*")
@onready var cutscene_enter_rea: Area2D = $TransformKiller_____/CutsceneEnterRea


func _ready() -> void:
	DAT.set_data(VISITS, girl_visits)
	if not Math.inrange(ResMan.get_character("greg").level, 40, 49) or DAT.get_data(VAMP_FOUGHT, false):
		queue_free()
		return
	if DAT.get_data(GUY_FOLLOW, false):
		uguy_follow()
		return
	if location == Locations.TOWN_PARK:
		position = Vector2(9999, 9999)
		cutscene_enter_rea.body_entered.connect(func(_a) -> void:
			if girl_inters <= 0:
				girl_visits.append(location)
				park_cutscene()
		)
		if girl_inters == 5 and LTS.gate_id == &"town-police":
			_after_police_cutscene()

	elif location == Locations.GAMER:
		if not _pre_setup_basic(2): return
		var gamer: OverworldCharacter = $"../Guy"
		gamer.default_lines = ["gamer_girl_gamer"]
	elif location == Locations.POST:
		if not _pre_setup_basic(3): return
		if DAT.get_data("biking_games_finished", 0) < 1:
			uguy.default_lines = []
	elif location == Locations.STORE:
		var store := $".."
		await get_tree().process_frame # store cashier gets overridden in stores _ready
		DAT.set_data("v_cs_cashier", store.store_cashier.cashier)
		if not _pre_setup_basic(4): return
	elif location == Locations.POLICE:
		if not _pre_setup_basic(5): return
		var the_waiter: OverworldCharacter = $"../TheWaiter"
		await get_tree().process_frame
		the_waiter.default_lines = [&"girl_popo_waiter"]
		cutscene_enter_rea.body_entered.connect(func(_a) -> void:
			if girl_inters == 4 and not DAT.get_data(GUY_FOLLOW, false):
				_police_cutscene()
		)


func _pre_setup_basic(inters: int) -> bool:
	if girl_inters <= 0 or (location in girl_visits and girl_inters == inters):
		queue_free()
		return false
	if not location in girl_visits:
		girl_visits.append(location)
	SND.play_song.call_deferred("sweet_girls", 1.0, {play_from_beginning = true})

	girl.inspected.connect(func() -> void:
		girl_inters += 1
	, CONNECT_ONE_SHOT)
	return true


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


func _after_police_cutscene() -> void:
	$"../../Houses/Police/DoorArea".set_collision_layer_value(3, false)
	await create_tween().tween_interval(1.0).finished
	DAT.capture_player("cutscene")
	greg.animate("walk_up")
	await Math.timer(0.3)
	uguy.global_position = $"../../Houses/Police/DoorArea/Node2D".global_position
	SND.play_sound(preload("res://sounds/door/close.ogg"))
	SOL.dialogue("uguy_lost")
	await SOL.dialogue_closed
	DAT.free_player("cutscene")
	DAT.set_data(GUY_FOLLOW, true)
	uguy_follow()
	$"../../Houses/Police/DoorArea".set_collision_layer_value(3, true)


func _police_cutscene() -> void:
	girl_inters += 1
	DAT.capture_player("cutscene")
	greg.animate("walk_right")
	var popo: OverworldCharacter = $"../Popo1"
	var station: PoliceStation = $"../.."
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(camera, ^"global_position", popo.global_position.lerp(girl.global_position, .5).floor(), 1.0)
	await tw.finished
	var dlg := DialogueBuilder.new()
	dlg.set_char("vampire_talk")
	girl.direct_walking_animation(girl.global_position.direction_to(greg.global_position))
	popo.enter_a_state_of_conversation()
	popo.direct_walking_animation(Vector2.LEFT)
	dlg.add_line(dlg.ml("see? he even followed me here, the dodgy bugger!"))
	dlg.add_line(dlg.ml("wow... he really did...").scharacter("popo_1"))
	dlg.add_line(dlg.ml("you must feel really special..."))
	dlg.add_line(dlg.ml("i do! ...unrelated to him!!!!").scharacter("vampire_talk"))
	dlg.add_line(dlg.ml("are you gonna do something??"))
	dlg.add_line(dlg.ml("if you insist...").scharacter("popo_1"))
	await dlg.speak_choice()
	popo.move_to(Vector2(popo.global_position.x, greg.global_position.y))
	await popo.target_reached
	await get_tree().process_frame
	popo.direct_walking_animation(Vector2.LEFT)
	dlg.reset()
	dlg.add_line(dlg.ml("hey! you got some dirt on this girl?"))
	dlg.add_line(dlg.ml("you must be suspicious of something!"))
	dlg.add_line(dlg.ml("i'm literally right here.").scharacter("vampire_talk").scallback(func() -> void: girl.direct_walking_animation(girl.global_position.direction_to(popo.global_position))))
	dlg.add_line(dlg.ml("sure! it's an interrogation!").scharacter("popo_1").scallback(func() -> void: popo.direct_walking_animation(popo.global_position.direction_to(girl.global_position))))
	dlg.add_line(dlg.ml("spit it out! what have you done?"))
	dlg.add_line(dlg.ml("i have been followed by a creep!!!").scharacter("vampire_talk"))
	dlg.add_line(dlg.ml("i demand to have my complaints heard!"))
	dlg.add_line(dlg.ml("we have some relaxing \"[font_size=9]jale cells[/font_size]\" over there...").scharacter("popo_1").sportrait_scale(Vector2(1, 1.1)))
	dlg.add_line(dlg.ml("you can wait inside while we sort it out here..."))
	dlg.add_line(dlg.ml("you're ridiculous!").scharacter("vampire_talk"))
	dlg.add_line(dlg.ml("this entire establishment is!!"))
	dlg.add_line(dlg.ml("i'll be leaving! goodbye!"))
	await dlg.speak_choice()

	girl.move_to(Vector2(-55, -9))
	await girl.target_reached
	await get_tree().process_frame
	girl.move_to(Vector2(-53, 40))
	await girl.target_reached
	await get_tree().process_frame
	girl.move_to(Vector2(-24, 46))
	await girl.target_reached
	await get_tree().process_frame
	girl.hide()
	SND.play_sound(preload("res://sounds/door/close.ogg"))
	SND.play_song("", 99)
	girl.global_position = Vector2(999, 999)
	await Math.timer(1.0)
	dlg.reset().set_char("popo_1")
	dlg.add_line(dlg.ml("man... what was that girl's problem?"))
	dlg.add_line(dlg.ml("if you followed me around town all day, i'd be ecstatic."))
	dlg.add_line(dlg.ml("i think you should keep following her!"))
	await dlg.speak_choice()
	tw = create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(camera, ^"position", Vector2(0, -9), 2.0)
	await tw.finished
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
	campsite_area.body_entered.connect(func(body: Node2D):
		if body != greg or not DAT.get_data(GUY_FOLLOW, false):
			return
		LTS.gate_id = &"vampire_cutscene"
		LTS.level_transition("res://scenes/rooms/scn_room_town.tscn")
	)


func _on_uguy_cannot_reach_target() -> void:
	print("a")
	if not DAT.get_data(GUY_FOLLOW, false):
		return
	var tw := create_tween()
	SND.play_sound(preload("res://sounds/teleport.ogg"), {"pitch_scale": randf_range(0.9, 1.2)})
	tw.tween_property(uguy, "global_position", greg.global_position, 0.1)
