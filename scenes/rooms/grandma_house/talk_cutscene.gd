extends Node2D

const G := preload("res://scenes/characters/overworld/scr_grandma_overworld.gd")
const FLOWERCOLOR := "#99ff61"

@onready var grandma: G = $"../Grandma"
@onready var greg: PlayerOverworld = $"../Greg"
@onready var camera: Camera2D = $"../Greg/Camera"
@onready var room_center: Marker2D = $RoomCenter
@onready var radio: Node2D = $"../Radio"
@onready var radio_music: AudioStreamPlayer2D = $"../Radio/RadioMusic"
@onready var zoom_gradient: TextureRect = $"../ZoomGradient"
@onready var color_container: ColorContainer = $"../CanvasModulateGroup/ColorContainer"
var initial_color: Color


func _ready() -> void:
	grandma.inspected.connect(initial_interaction)
	$InteractionArea.interacted.connect(initial_interaction)
	initial_color = color_container.color



func initial_interaction() -> void:
	DAT.capture_player("cutscene")
	zoom_gradient.get_parent().remove_child(zoom_gradient)
	room_center.add_child(zoom_gradient)
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
	SND.play_song("")
	SOL.vfx_damage_number(grandma.global_position, "oh!", Color.WHITE, 1.0, {parent = grandma})
	grandma.direct_walking_animation(Vector2.DOWN)
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
	SND.play_song("grandma_scary", 0.3, {pitch_scale = 0.76})
	var dlg := DialogueBuilder.new().set_char("grandma_talk")
	dlg.add_line(dlg.ml("well well well... look who it is..."))
	var t2 := create_tween().set_trans(Tween.TRANS_BOUNCE)
	zoom_gradient.show()
	t2.tween_property(zoom_gradient, "modulate:a", 1.0, 7.0).from(0.0)
	t2.parallel().tween_property(color_container, "color",
		Color(0.512, 0.629, 0.815), 7.0)
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
	t2.kill()
	zoom_gradient.hide()
	color_container.color = initial_color
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
	dlg.add_line(dlg.ml("last day of school! divorce! walking your dog!")
		.scallback(func() -> void:
			grandma.tanim_shake(20, 4.0)
			grandma.sanimate("halgful_left")
	))
	dlg.add_line(dlg.ml("there is a flower for every occasion.")
		.scallback(func() -> void:
			grandma.tanim_bounce(1.4)
			grandma.sanimate("smile")
	))
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
	var about_talked := false
	DAT.free_player("cutscene")
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
			break
		elif choice == &"aboutyou":
			dlg.reset().set_char("grandma_talk")
			dlg.add_line(dlg.ml("about me?")
				.scallback(func() -> void:
					grandma.sanimate("")
					grandma.direct_walking_animation(Vector2.DOWN)
			))
			dlg.add_line(dlg.ml("i'm just a lonely old florist, dear.")
				.scallback(grandma.direct_walking_animation.bind(
					grandma.global_position.direction_to(greg.global_position))
			))
			dlg.add_line(dlg.ml("but you can call me grandma for short!")
				.scallback(grandma.sanimate.bind("spin")))
			dlg.add_line(dlg.ml("i don't get called that often anymore.")
				.scallback(grandma.sanimate.bind("sad")))
			dlg.add_line(dlg.ml("people tend to forget things with age, you see..."))
			dlg.add_line(dlg.ml("i have no idea where my grandchildren are!")
				.scallback(func() -> void:
					grandma.tanim_shake(20, 4.0)
					grandma.sanimate("halgful_right")
			))
			dlg.add_line(dlg.ml("i've forgotten where all of them went!")
				.scallback(func() -> void:
					grandma.tanim_shake(20, 4.0)
					grandma.sanimate("halgful_left")
			))
			dlg.add_line(dlg.ml("i say good riddance! i don't even want to see them!")
				.scallback(func() -> void:
					grandma.tanim_bounce(1.2)
					grandma.sanimate("smile")
			))
			dlg.add_line(dlg.ml("to explain, dear, what i have failed to grow in people...")
				.scallback(func() -> void:
					grandma.sanimate("")
					grandma.direct_walking_animation(
						grandma.global_position.direction_to(greg.global_position))
			))
			dlg.add_line(dlg.ml("...i make up for in plants. and such.")
				.scallback(grandma.sanimate.bind("spin")))

			await dlg.speak_choice()
		elif choice == &"aboutme":
			dlg.reset().set_char("grandma_talk")
			if not about_talked:
				dlg.add_line(dlg.ml("about you?")
					.scallback(func() -> void:
						grandma.sanimate("")
						grandma.direct_walking_animation(Vector2.DOWN)
				))
				dlg.add_line(dlg.ml("you want to know more about yourself, dear?")
					.scallback(grandma.direct_walking_animation.bind(
						grandma.global_position.direction_to(greg.global_position))))
				dlg.add_line(dlg.ml("i don't know if i can help you with that, sorry..."))
				dlg.add_line(dlg.ml("say... listen to this old florist's advice:"))
				dlg.add_line(dlg.ml("keep yourself occupied! there's so much to do in the world...")
					.scallback(grandma.sanimate.bind("spin")))
				dlg.add_line(dlg.ml("places to go! plants to care for! people to water!")
					.scallback(grandma.sanimate.bind("spin_fast")))
				dlg.add_line(dlg.ml("ahh, so much to do!! i want to explode!!")
					.scallback(func() -> void:
						grandma.sanimate("spin_fast", 2.0)
						grandma.tanim_shake(20, 8)
						grandma.particles(1.0, 0.2, 8.0)
				))
				dlg.add_line(dlg.ml("this week, i think i will focus on cleaning up.")
					.scallback(func() -> void:
						grandma.tanim_bounce(1.2)
						grandma.sanimate("smile")
						grandma.particles()
				))
				dlg.add_line(dlg.ml("there are some loose ends here and there."))
				about_talked = true
			else:
				dlg.add_line(dlg.ml("...")
					.scallback(func() -> void:
						grandma.sanimate("")
						grandma.direct_walking_animation(Vector2.DOWN)))
				dlg.add_line(dlg.ml("haven't i seen you before, dear?")
					.scallback(grandma.direct_walking_animation.bind(
						grandma.global_position.direction_to(greg.global_position))))
				dlg.add_line(dlg.ml("it could have been a long time ago."))
				dlg.add_line(dlg.ml("have you lived here before?"))

			await dlg.speak_choice()
			grandma.sanimate("")
		elif choice == &"house":
			dlg.reset().set_char("grandma_talk")
			dlg.add_line(dlg.ml("this house?"))
			dlg.add_line(dlg.ml("i got it recently! it's a lovely spot next to the woods."))
			dlg.add_line(dlg.ml("although, not very good for business...").schoices(["mine"]))
			dlg.add_line(dlg.ml("huh? so you have lived here? that's why your face seemed familiar!").schoices(["give"]))
			dlg.add_line(dlg.ml("...what?").schoices(["give house"])
				.scallback(func() -> void:
					if is_instance_valid(SND.current_song_player):
						var tw := create_tween()
						tw.tween_property(SND.current_song_player, ^"pitch_scale", 0.88, 4.0)
			))
			dlg.add_line(dlg.ml("no??? it's my house???").schoices(["i need it"])
				.scallback(func() -> void:
					grandma.tanim_shake(10, 4.0)
					grandma.sanimate("shock")
			))
			dlg.add_line(dlg.ml("no!!").schoices(["give me house"]))
			dlg.add_line(dlg.ml("stop that!!").schoices(["mmm house"]))
			dlg.add_line(dlg.ml("fine! if you're really that persistent...")
				.scallback(func() -> void:
					grandma.sanimate("")
					grandma.direct_walking_animation(Vector2.DOWN)
			))
			dlg.add_line(dlg.ml("i'll test you.")
				.scallback(func() -> void:
					grandma.sanimate("smile")
			))
			dlg.add_line(dlg.ml("are you worthy of this place? or was leaving in the first place..."))
			dlg.add_line(dlg.ml("...the weakness that still follows you?"))

			await dlg.speak_choice()
			LTS.enter_battle(preload("res://resources/battle_infos/grandma_intro.tres"))
			break
		else:
			assert(false)
