extends Node2D

const G := preload("res://scenes/characters/overworld/scr_grandma_overworld.gd")

const FLOWERCOLOR := "#99ff61"

@onready var greg: PlayerOverworld = $"../Greg"
@onready var grandma: G = $"../Grandma"
@onready var camera: Camera2D = $"../Greg/Camera"
@onready var color_container: ColorContainer = $"../CanvasModulateGroup/ColorContainer"
@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var zoom_gradient: TextureRect = $"../ZoomGradient"

var dlg := DialogueBuilder.new()
var initial_color: Color


func _ready() -> void:
	if LTS.gate_id != &"lol":
		queue_free()
		return
	initial_color = color_container.color
	DAT.capture_player("cutscene")
	remove_child(dialogue_box)
	SOL.add_ui_child(dialogue_box)
	dialogue_box.position = Vector2.ZERO
	await cs1()


func cs1() -> void:
	greg.remove_child(camera)
	add_child(camera)
	$"../Radio/RadioMusic".stop.call_deferred()
	camera.global_position = global_position
	greg.global_position = global_position - Vector2(8, 0)
	grandma.global_position = global_position - Vector2(0, 10)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	greg.rotate(deg_to_rad(90))
	SND.play_sound(preload("res://sounds/pathetic_topple.ogg"))
	tw.tween_property(greg, ^"global_position", global_position + Vector2(-8, 15), 0.9)
	tw.parallel().tween_method(func(f: float) -> void:
		greg.raycast.target_position = Vector2.from_angle(f)
		greg.direct_animation()
	, TAU * 2, 0.0, 1.0).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.0)
	tw.tween_callback(func() -> void:
		SND.play_song("grandma_scary", 0.5, {play_from_beginning = true})
		grandma.sanimate("walk_down", 0.1)
		dlg.reset().set_char("grandma_talk")
		dlg.add_line(dlg.ml("greg.").stext_speed(0.3))
		dlg.add_line(dlg.ml("greg, you little... man.").stext_speed(0.3))
		dlg.speak(dialogue_box)
	)
	tw.tween_property(color_container, ^"color", Color(0.314, 0.571, 0.406), 2.0)
	tw.parallel().tween_property(grandma, ^"global_position", global_position + Vector2(0, 12), 4.0)
	tw.parallel().tween_property(camera, ^"zoom", Vector2.ONE * 2, 4.0)
	await tw.finished
	grandma.sanimate("")
	dlg.reset().set_char("grandma_talk")
	dlg.add_line(dlg.ml("is this how you treat a lonely old florist?").stext_speed(0.5)
		.scallback(func() -> void:
			zoom_gradient.show()
			var t := create_tween()
			t.tween_property(zoom_gradient, ^"modulate:a", 0.5, 4.0).from(0.0)
			t.parallel().tween_method(func(f: float) -> void:
				grandma.particles(f, 1.0, f * 8.0)
			, 0.0, 0.5, 4.0)
	))
	dlg.add_line(dlg.ml("you are not fit for this house.").stext_speed(0.5)
		.scallback(func() -> void:
			var t := create_tween()
			t.tween_property(zoom_gradient, ^"modulate:a", 1.0, 4.0)
			t.parallel().tween_method(func(f: float) -> void:
				grandma.particles(f, 1.0, f * 8.0)
			, 0.5, 1.0, 4.0)
	))
	await dlg.speak_choice(dialogue_box)
	dialogue_box.set_process_unhandled_input(false)
	var dlg2 := DialogueBuilder.new()
	dlg2.add_line(dlg.ml("..."))
	dlg2.speak(dialogue_box)
	tw = create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(camera, "zoom", Vector2.ONE, 4.0)
	tw.parallel().tween_property(zoom_gradient, ^"modulate:a", 0.0, 16.0)
	tw.parallel().tween_property(color_container, ^"color", Color(0.78, 0.932, 0.768), 8.0)
	dialogue_box.close()
	dlg.reset().set_char("grandma")
	dlg.add_line(dlg.ml("but."))
	dlg.add_line(dlg.ml("you have this drive, don't you, dear?"))
	dlg.add_line(dlg.ml("you want your house... you need it."))
	dlg.add_line(dlg.ml("perhaps we could discuss it."))
	dlg.add_line(dlg.ml("you have to mend our strained relationship, first."))
	await dlg.speak_choice()
	dialogue_box.close()

	dlg2.reset().set_char("silent").add_line(dlg.ml("show me you are capable").stext_speed(0.5))
	dlg.reset().set_char("grandma_talk").add_line(dlg.ml("it's nice to gift flowers."))
	dlg2.speak(dialogue_box)
	await dlg.speak_choice()
	dialogue_box.close()

	dlg2.reset().set_char("silent").add_line(dlg.ml("of taking them on").stext_speed(0.5))
	dlg.reset().set_char("grandma_talk").add_line(dlg.ml("maybe, if you find [color=%s]eight flowers..." % FLOWERCOLOR))
	dlg2.speak(dialogue_box)
	await dlg.speak_choice()
	dialogue_box.close()

	dlg2.reset().set_char("silent").add_line(dlg.ml("bring me their heads").stext_speed(0.5))
	dlg.reset().set_char("grandma_talk").add_line(dlg.ml("assemble a nice bouquet."))
	dlg2.speak(dialogue_box)
	await dlg.speak_choice()
	dialogue_box.close()

	dlg2.reset().set_char("silent").add_line(dlg.ml("and i will crown yours").stext_speed(0.4))
	dlg.reset().set_char("grandma_talk").add_line(dlg.ml("and then, we can talk in a civilised manner."))
	dlg2.speak(dialogue_box)
	await dlg.speak_choice()
	dialogue_box.close()
	dialogue_box.hide()

	await Math.timer(1.8)
	SND.play_song("", 9999)
	color_container.color = initial_color
	grandma.sanimate("walk_down", 4.0)
	dlg.reset().set_char("grandma").add_line(dlg.ml("what the hell are you waiting for??"))
	dlg.add_line(dlg.ml("go get me the damn flowers!!").scharacter("grandma_talk")
		.scallback(func() -> void:
			grandma.sanimate("halgful", 1.5)
			grandma.tanim_bounce(1.0)
	))
	await dlg.speak_choice()
	grandma.sanimate("spin_fast", 2.0)
	SND.play_sound(preload("res://sounds/whoosh.ogg"))
	tw = create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(grandma, ^"global_position", greg.global_position, 0.1)
	tw.tween_interval(0.1)
	tw.tween_callback(func() -> void:
		SOL.vfx("explosion", greg.global_position, {parent = grandma, scale = Math.v2(0.3)})
		SND.play_sound(preload("res://sounds/critical_hit.ogg"))
	)
	tw.tween_property(greg, ^"global_position:y", 80, 0.15).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(greg, ^"rotation", TAU * 2, 0.2)
	tw.tween_interval(0.07)
	tw.tween_callback(func() -> void:
		LTS.gate_id = &"greghouse_inside-outside"
		LTS.level_transition(LTS.ROOM_SCENE_PATH % "greg_house")
		DAT.set_data("intro_progress", 2)
		DAT.free_player("cutscene")
	)
