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
		dlg.al("let's see your bouquet, dear!").scallback(func() -> void:
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
		dlg.al("what a lovely bouquet!").scallback(func() -> void:
			grandma.sanimate("smile")
			grandma.tanim_bounce(1.4)
		)
		dlg.al("tasteful! tasty!!").scallback(func() -> void:
			grandma.sanimate("halgful_right")
			grandma.tanim_shake(10, 1.4)
		)
		dlg.al("gathered from fools who never should have had flowers at all!")
		dlg.al("and you - look at you, now!").scallback(func() -> void:
			grandma.sanimate("smile")
			grandma.tanim_bounce(1.4)
		)
		dlg.al("aren't you proud of your hard-earned %s levels?" % gchar.level)
		if gchar.level >= 99:
			dlg.al("even if that much is a bit excessive?? dude??")
		dlg.al("each ugly mug you smashed into the dirt...").scallback(grandma.sanimate.bind("spin"))
		dlg.al("they should be thankful to have found an actual use!!")
		dlg.al("needless to say, dear, i am very impressed by your resolve!").scallback(grandma.sanimate.bind("walk_down", 0.0))
		dlg.al("so, your house, dear - sorry about the mess -")
		dlg.al("...you recognised your house, right?").scallback(grandma.sanimate.bind("walk_left", 0.0))
		dlg.al("i was in a bit of a hurry, but it is yours...")
		dlg.al("since you got me the flowers...").scallback(grandma.sanimate.bind("walk_down", 0.0))
		dlg.al("we can now... talk about it!").scallback(grandma.sanimate.bind("smile", 0.0))
		dlg.al("...").scallback(func() -> void:
			SND.play_song("", 999)
			#grandma.sanimate("walk_up", 0.0)
		)
		await dlg.speak_choice()
		await Math.timer(1.0)
		dlg.reset()
		dlg.al("talking... love doing it.")
		await dlg.speak_choice()
		await Math.timer(2.0)
		dlg.reset()
		dlg.al("well!!!! i'm so glad you want to live in your house!!!! here!!!!")
		dlg.al("in your house... here. this house.")
		dlg.al("...forever.")
		dlg.al("well, also, ")
		dlg.al("...i'm sorry. this next part will be a bit contrived.")
		dlg.al("have you thought about growing old and dying?").scallback(grandma.sanimate.bind("walk_down", 0.0))
		await dlg.speak_choice()
		await Math.timer(2.0)
		dlg.reset()
		dlg.al("just saying...").scallback(grandma.sanimate.bind("walk_right", 0.0))
		dlg.al("you would last forever in stone.").stext_speed(0.4).scallback(grandma.sanimate.bind("walk_down", 0.0))
		await dlg.speak_choice()
		SND.play_sound(preload("res://sounds/enter_battle_grandma.ogg"), {pitch_scale = 0.78})
		await Math.timer(0.6)
		LTS.enter_battle(preload("res://resources/battle_infos/grandma_bossfight.tres"))
	)
