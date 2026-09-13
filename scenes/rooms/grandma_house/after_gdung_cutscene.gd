extends Node2D

const FlowerCircle = preload("res://scenes/cutscene/flower_circle.gd")

@onready var enter_area: Area2D = $EnterArea
@onready var camera: Camera2D = $"../../Greg/Camera"
@onready var grandma := $Grandma
@onready var flower_circle: FlowerCircle = $FlowerCircle
@onready var walk_up_position: Marker2D = $WalkUpPosition
@onready var walking: AudioStreamPlayer = $Walking

@export var greg: PlayerOverworld
@export var color_container: ColorContainer


func _ready() -> void:
	grandma.set_physics_process(false)
	enter_area.body_entered.connect(_close_cutscene.unbind(1))


func _close_cutscene() -> void:
	var dlg := DialogueBuilder.new().set_char("grandma_talk")
	var gchar := ResMan.get_character("greg")
	var t2 := create_tween().set_loops()
	t2.pause()
	t2.tween_callback(walking.play)
	t2.tween_interval(0.66667)
	SND.play_song("")
	DAT.capture_player("cutscene")
	greg.animate("walk_up")
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.parallel().tween_property(greg, "global_position:x", walk_up_position.global_position.x, 0.5)
	tw.tween_callback(greg.animate.bind("walk_up", 0.6))
	tw.tween_callback(t2.play)
	tw.tween_property(greg, ^"global_position",
			walk_up_position.global_position, 4.0)
	tw.parallel().tween_property(camera, ^"global_position",
			walk_up_position.global_position - Vector2(0, 20), 4.0)
	tw.tween_callback(t2.stop)
	tw.tween_callback(greg.animate.bind("walk_up"))
	tw.tween_interval(1.0)
	tw.tween_callback(func():
		dlg.al("well well well. look who it is.")
		dlg.al("the little... man. greg.").scallback(grandma.sanimate.bind("backward_look"))
		dlg.al("and with him, he has...")
		dlg.al("the [color=%s]flowers!!" % dlg.FLOWERCOLOR).scallback(func() -> void:
			grandma.sanimate("smile")
			grandma.tanim_bounce(1.4)
			SND.play_song_from_beginning("grand", 99)
		)
		await dlg.speak_choice()
		grandma.sanimate("flip")
		await Math.timer(0.7)
		dlg.reset()
		dlg.al("gimme gimme!!").scallback(func() -> void:
			grandma.sanimate("smile")
			grandma.tanim_bounce(1.4)
		)
		await dlg.speak_choice()
		flower_circle.show()
		flower_circle.found = 4
		flower_circle.show_cool()
		for f in DAT.FLOWERS:
			gchar.inventory.erase(f)
		await Math.timer(1.0)
		dlg.reset()
		dlg.al("oh, beautiful! what adventures you've had!").scallback(grandma.sanimate.bind("backward"))
		dlg.al("disappointing ones! inane ones!").scallback(grandma.sanimate.bind("backward_look"))
		dlg.al("all those people who thought they were the boss...").scallback(grandma.sanimate.bind("backward"))
		dlg.al("...no, dear. i'm the boss.").scallback(func() -> void:
			grandma.tanim_bounce(1.4)
			grandma.sanimate("halgful_right")
			grandma.tanim_shake(10, 1.4)
		)
		dlg.al("thanks, dear. i really mean it.").scallback(func() -> void:
			grandma.sanimate("dance")
		)
		dlg.al("you've made my life so much easier...")
		dlg.al("i've got barely anything left to clean up, now.").scallback(func() -> void:
			grandma.sanimate("smile")
			grandma.tanim_bounce(1.4)
		)
		dlg.al("there's only one thing.").scallback(func() -> void:
			grandma.sanimate("backward")
			SND.play_song("", 999)
		)
		dlg.al("our deal... about your house.").scallback(grandma.sanimate.bind("backward_look"))
		dlg.al("i'll even be generous and ignore you tresspassing...").scallback(grandma.sanimate.bind("walk_down", 0.0))
		dlg.al("...through my secret garden.")
		dlg.al("where i... grow... my secret... flowers...?").scallback(grandma.sanimate.bind("walk_left", 0.0))
		dlg.al("...").scallback(func() -> void:
			grandma.sanimate("walk_down", 0.0)
		)
		await dlg.speak_choice()
		await Math.timer(1.0)
		dlg.reset()
		dlg.al("whatever. let's talk, greggy boy.")
		await dlg.speak_choice()
		LTS.enter_battle(preload("res://resources/battle_infos/grandma_bossfight.tres"), {"sound": preload("res://sounds/enter_battle_grandma.ogg")})
	)
