extends Node2D

const G := preload("res://scenes/characters/overworld/scr_grandma_overworld.gd")
const FLOWERCOLOR := "#99ff61"

@onready var grandma: G = $"../Grandma"
@onready var greg: PlayerOverworld = $"../Greg"
@onready var camera: Camera2D = $"../Greg/Camera"
@onready var room_center: Marker2D = $RoomCenter
@onready var radio: Node2D = $"../Radio"
@onready var radio_music: AudioStreamPlayer2D = $"../Radio/RadioMusic"


func _ready() -> void:
	grandma.inspected.connect(initial_interaction)
	$InteractionArea.interacted.connect(initial_interaction)


func initial_interaction() -> void:
	DAT.capture_player("cutscene")
	grandma.inspected.disconnect(initial_interaction)
	$InteractionArea.interacted.disconnect(initial_interaction)
	grandma.inspected.connect(second_interaction)
	await cs_setup()
	await cs_talk_1()
	await cs_talk_2()


func second_interaction() -> void:
	await cs_talk_2()


func cs_setup() -> void:
	SND.play_sound(preload("res://sounds/talking/grandma.ogg"), {loop = false})
	SND.play_song("grandma_scary", 0.3, {pitch_scale = 0.76})
	SOL.vfx_damage_number(grandma.global_position, "oh!", Color.WHITE, 1.0, {parent = grandma})
	await grandma.tanim_shake(8, 4)
	await Math.timer(0.2)
	grandma.speed = 9000
	grandma.collision_mask = 0
	grandma.move_to(radio.global_position + Vector2(0, 16))
	await grandma.target_reached
	radio_music.stop()
	SND.play_sound(preload("res://sounds/misc_click.ogg"))
	await Math.timer(0.2)
	grandma.move_to(room_center.global_position + Vector2(room_center.gizmo_extents, 0))
	var tw := create_tween()
	var mt := 0.5
	tw.tween_property(
		greg, "global_position",
		room_center.global_position - Vector2(room_center.gizmo_extents, 0), mt)
	greg.animate("walk_down", true, 2.0)
	tw.parallel().tween_property(
		camera, "global_position",
		room_center.global_position + Vector2(0, -10), mt)
	grandma.target_reached.connect(grandma.sanimate.bind("walk_left", 0.0))
	await tw.finished
	greg.animate("walk_right")
	await Math.timer(0.6)


func cs_talk_1() -> void:
	var dlg := DialogueBuilder.new().set_char("grandma_talk")
	dlg.add_line(dlg.ml("well well well... look who it is..."))
	grandma.sanimate("walk_left", 0.001)
	await dlg.speak_choice()
	var tw := create_tween()
	tw.tween_property(grandma, "global_position", room_center.global_position, 2.0)
	dlg.reset().set_char("grandma_talk")
	dlg.add_line(dlg.ml("you... are..."))
	dlg.speak()
	await tw.finished
	if SOL.dialogue_open:
		await SOL.dialogue_closed
	tw = create_tween()
	tw.tween_property(grandma, "global_position",
		room_center.global_position + Vector2(room_center.gizmo_extents, 0), 0.1)
	dlg.reset().set_char("grandma_talk")
	dlg.add_line(dlg.ml("a customer!!!"))
	dlg.add_line(dlg.ml("a customer in my [color=%s]flower shop![/color]" % FLOWERCOLOR))
	SND.play_song("grand", 99.0, {play_from_beginning = true})
	grandma.tanim_shake(10, 4.0)
	grandma.sanimate("happy")
	await dlg.speak_choice()
	grandma.sanimate("flip")
	await Math.timer(1.5)
	grandma.sanimate("")
	grandma.direct_walking_animation(Vector2.LEFT)
	dlg.reset().set_char("grandma_talk")
	dlg.add_line(dlg.ml("so, dear, tell me what you need..."))
	dlg.add_line(dlg.ml("flowers are wonderful for many occasions!")
		.scallback(grandma.sanimate.bind("dance")))
	dlg.add_line(dlg.ml("birthdays! dates! first day of school!")
		.scallback(grandma.sanimate.bind("spin")))
	dlg.add_line(dlg.ml("last day of school! breakups! walking your dog!")
		.scallback(func() -> void: grandma.tanim_shake(20, 4.0); grandma.sanimate("halgful_left")))
	dlg.add_line(dlg.ml("there is a flower for every occasion.")
		.scallback(func() -> void: grandma.tanim_bounce(1.0); grandma.sanimate("smile")))
	dlg.add_line(dlg.ml("here, dear, to celebrate - a flower on the house!")
		.scallback(func() -> void:
			grandma.sanimate("")
			grandma.direct_walking_animation(Vector2.LEFT)
	))
	await dlg.speak_choice()
	DAT.grant_item("flower_strawberry")
	await SOL.dialogue_closed


func cs_talk_2() -> void:
	var aval_choices := ["aboutyou", "aboutme", "house", "bye"]
	var dlg := DialogueBuilder.new()
	while true:
		dlg.reset().set_char("grandma_talk")
		var welcome := "wonderful young man! what do you wish to do?"
		if SND.current_song_key != "grand":
			welcome = "you didn't like my music...?"
		dlg.add_line(dlg.ml(welcome)
			.schoices(aval_choices)
			.scallback(func() -> void:
				grandma.sanimate("smile")
				grandma.tanim_bounce(1.0, 0.9)
		))
		var choice := await dlg.speak_choice()
		if choice == &"bye":
			dlg.reset().set_char("grandma_talk")
			dlg.add_line(dlg.ml("there's no rush, dear! stop and smell the flowers!")
				.scallback(func() -> void:
					grandma.sanimate("spin", 0.8)
			))
			await dlg.speak_choice()
			grandma.sanimate("")
			DAT.free_player("cutscene")
			break
		elif choice == &"aboutyou":
			dlg.reset().set_char("grandma_talk")
			dlg.add_line(dlg.ml("about me?")
				.scallback(func() -> void:
					grandma.sanimate("")
					grandma.direct_walking_animation(Vector2.DOWN)
			))
			dlg.add_line(dlg.ml("i'm just a lonely old florist, dear.")
				.scallback(func() -> void:
					grandma.direct_walking_animation(
						grandma.global_position.direction_to(greg.global_position))
			))

			await dlg.speak_choice()
		else:
			break
