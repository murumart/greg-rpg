extends Node2D

@onready var enter_area: Area2D = $EnterArea
@onready var camera: Camera2D = $"../../Greg/Camera"
@onready var grandma := $Grandma
@onready var flower_circle: Node2D = $FlowerCircle

@export var greg: PlayerOverworld
@export var color_container: ColorContainer


func _ready() -> void:
	grandma.set_physics_process(false)
	enter_area.body_entered.connect(_close_cutscene.unbind(1))


func _close_cutscene() -> void:
	var dlg := DialogueBuilder.new().set_char("grandma_talk")
	var gchar := ResMan.get_character("greg")
	SND.play_song("")
	DAT.capture_player("cutscene")
	greg.animate("walk_up")
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(camera, "global_position",
			((greg.global_position + grandma.global_position) * 0.5).ceil() - Vector2(0, 14), 2.3)
	tw.tween_interval(1.0)
	tw.tween_callback(func():
		dlg.al("you're here.")
		dlg.al("after all this time, you've made it...")
		dlg.al("despite every enemy and obstacle...").scallback(grandma.sanimate.bind("backward_look"))
		dlg.al("you showed me your resolve by...").scallback(grandma.sanimate.bind("backward"))
		dlg.al("bringing...")
		dlg.al("the [color=%s]flowers!" % dlg.FLOWERCOLOR).scallback(func() -> void:
			grandma.sanimate("smile")
			grandma.tanim_bounce(1.4)
			SND.play_song("grand", 99, {play_from_beginning = true})
		)
		await dlg.speak_choice()
		grandma.sanimate("flip")
		await Math.timer(0.7)
		dlg.reset()
		dlg.al("what a lovely bouquet, dear!").scallback(func() -> void:
			grandma.sanimate("smile")
			grandma.tanim_bounce(1.4)
		)
		dlg.al("tasteful! tasty!!")
		dlg.al("and gathered from fools who never should have had flowers at all!").scallback(func() -> void:
			grandma.sanimate("halgful_right")
			grandma.tanim_shake(10, 1.4)
		)
		dlg.al("let's see it!").scallback(func() -> void:
			grandma.sanimate("smile")
			grandma.tanim_bounce(1.4)
		)
		await dlg.speak_choice()
		flower_circle.show()
		var i := 0
		for c: Sprite2D in flower_circle.get_children():
			c.modulate.a = 0.0
			var ft := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			ft.tween_interval(i * 0.12)
			ft.tween_callback($ItemSound.play)
			ft.tween_property(c, ^"scale", Vector2.ONE, 0.3).from(Vector2.ONE * 4)
			ft.parallel().tween_property(c, ^"modulate:a", 1.0, 0.3)
			i += 1
		for f in DAT.FLOWERS:
			gchar.inventory.erase(f)
		await Math.timer(1.0)
		dlg.reset()
		dlg.al("ah ha ha! looking at them almost reminds me of why i gave them away!").scallback(grandma.sanimate.bind("backward"))
		dlg.al("...almost!! i still don't remember!! anyway!").scallback(grandma.sanimate.bind("backward_look"))
		dlg.al("you - look at you, now!").scallback(grandma.sanimate.bind("smile"))
		dlg.al("aren't you proud of your hard-earned %s levels?" % gchar.level)
		if gchar.level >= 99:
			dlg.al("even if that much is a bit excessive?? dude??")
		dlg.al("each ugly mug you smashed into the dirt...").scallback(grandma.sanimate.bind("spin"))
		dlg.al("they should be thankful to have found an actual use!!")
		dlg.al("needless to say, dear, i am very impressed by your resolve!").scallback(grandma.sanimate.bind("walk_down", 0.0))
		dlg.al("so, your house, dear - sorry about the mess -")
		dlg.al("...you recognise your house, right?").scallback(grandma.sanimate.bind("walk_left", 0.0))
		dlg.al("even with all this... stuff in it...")
		dlg.al("...").scallback(func() -> void:
			SND.play_song("", 999)
			grandma.sanimate("walk_up", 0.0)
		)
		await dlg.speak_choice()
		await Math.timer(1.0)
		dlg.reset().set_char("silent")
		dlg.al("you know...").stext_speed(0.5)
		dlg.al("i could give you your house back.").stext_speed(0.5)
		dlg.al("i could send you riiight back to your doorstep.").stext_speed(0.5).scallback(grandma.sanimate.bind("backward_look"))
		dlg.al("you wouldn't even have to remember anything.").stext_speed(0.5)
		dlg.al("but you've been just so... useful!").stext_speed(0.5)
		dlg.set_char("grandma_talk")
		dlg.al("so, i have a better idea!").scallback(func() -> void:
			grandma.sanimate("smile")
			SND.play_song("byddd")
		)
		dlg.al("stay with me, instead!")
		dlg.al("...are you bothered by it?")
		dlg.al("you don't have to be... you don't have to feel anything, in fact.")
		dlg.al("you've grown into something good.").scallback(grandma.sanimate.bind("walk_down", 0.0))
		dlg.al("why let it go to waste?")
		dlg.al("you would last forever in stone.").stext_speed(0.3)
		await dlg.speak_choice()
		SND.play_sound(preload("res://sounds/enter_battle_grandma.ogg"), {pitch_scale = 0.78})
		await Math.timer(0.4)
		LTS.enter_battle(preload("res://resources/battle_infos/grandma_bossfight.tres"))
	)
