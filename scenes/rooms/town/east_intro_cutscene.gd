extends Node2D

const Mayor = preload("res://scenes/characters/overworld/scr_mayor_overworld.gd")

@onready var mayor: Mayor = $"../Mayor"
@onready var greg: PlayerOverworld = $"../../Greg"
@onready var path: Node2D = $Path


func _ready() -> void:
	if LTS.gate_id == &"town-east" and not DAT.get_data("saw_mayor_intro", false):
		_play_intro_cutscene()
		DAT.set_data("saw_mayor_intro", true)


func _play_intro_cutscene() -> void:
	var dlg := DialogueBuilder.new().set_char("mayor")
	SND.play_song.call_deferred("")
	DAT.capture_player(&"cutscene")
	await Math.timer(1.0)
	greg.animate("walk_right")
	dlg.add_line(dlg.ml("hold it right there, son."))
	await dlg.speak_choice()
	SND.play_song.call_deferred("mayor", 99, {play_from_beginning = true})
	var tw := create_tween()
	mayor.a_leg("walk", 2.0)
	tw.tween_property(mayor, ^"global_position", greg.global_position + Vector2(32, 0), 2.0)
	tw.tween_callback(mayor.a_leg.bind("default"))
	tw.tween_interval(0.4)
	await tw.finished
	dlg.reset().add_line(dlg.ml("i'm [color=ff4422]thick sauces[/color]."))
	dlg.add_line(dlg.ml("i'm the mayor."))
	dlg.add_line(dlg.ml("let's go for a stroll together."))
	await dlg.speak_choice()
	_walk()


var target_index: int = 0
func _walk() -> void:
	while target_index < path.get_child_count():
		mayor.a_leg("walk", 2.0)
		var tw := create_tween()
		var target: Node2D = path.get_child(target_index)
		var walkspeed := 60.0
		greg.raycast.target_position = greg.global_position.direction_to(target.global_position)
		greg.velocity = Vector2.RIGHT * walkspeed
		greg.direct_animation()
		tw.tween_property(
			mayor,
			^"global_position",
			target.global_position,
			mayor.global_position.distance_to(target.global_position) / walkspeed)
		tw.parallel().tween_property(
			greg,
			^"global_position",
			target.global_position - Vector2(12, 0),
			mayor.global_position.distance_to(target.global_position) / walkspeed)
		await tw.finished
		greg.animate("walk_right")
		mayor.a_leg("default")
		await _walkdial()
		target_index += 1
	SND.play_song((LTS.get_current_scene() as Room).music)
	mayor.animate(mayor.HEAD, "default")
	DAT.free_player("cutscene")


func _walkdial() -> void:
	var dlg := DialogueBuilder.new().set_char("mayor")
	match target_index:
		0:
			dlg.add_line(dlg.ml("i'm glad you're interested in settling here, son."))
			dlg.add_line(dlg.ml("our population has been on a grand decline."))
		1: dlg.add_line(dlg.ml("ignore the crime scene."))
		2:
			dlg.add_line(dlg.ml("your house of choice..."))
			dlg.add_line(dlg.ml("west of town, near the woods... good real estate."))
		3: dlg.add_line(dlg.ml("i take it that you've managed to strike a deal already."))
		4: dlg.add_line(dlg.ml("what a good stroll we're having.").scallback(mayor.animate.bind(mayor.HEAD, "default", 8.0, Vector2(0, 2))))
		5:
			dlg.add_line(dlg.ml("do you want a subsidy for settling here?").scallback(mayor.animate.bind(mayor.HEAD, "default", 0.0, Vector2(0, 0))))
			dlg.add_line(dlg.ml("take my money. (100 silver were received)").ssilver_to_give(100))
			dlg.add_line(dlg.ml("i hope you enjoyed this tour of my town."))
			dlg.add_line(dlg.ml("thank you again for deciding to live here."))
		6:
			dlg.add_line(dlg.ml("however, son."))
			dlg.add_line(dlg.ml("not quite enough, is it?").scallback(mayor.animate.bind(mayor.HEAD, "default", 8.0, Vector2(2, 0))))
			dlg.add_line(dlg.ml("you didn't even bring any children here.").scallback(SND.play_song.bind("")))
			dlg.add_line(dlg.ml("don't worry. i have a [color=ff4422]plan[/color].").scallback(mayor.animate.bind(mayor.HEAD, "default", 0.0, Vector2(0, 0))))
			dlg.add_line(dlg.ml("i'm going to open an [color=ff4422]evil portal[/color] to the [color=ff4422]spirit world[/color].").scallback(mayor.animate.bind(mayor.HEAD, "dark")))
			dlg.add_line(dlg.ml("spirits would love to [color=ff4422]settle[/color] in my [color=ff4422]town[/color].").scallback(mayor.a_rarm.bind("finger")))
			dlg.add_line(dlg.ml("i will do it. don't try to [color=ff4422]stop me[/color].").scallback(mayor.a_rarm.bind("hip")))
			dlg.add_line(dlg.ml("i'm the [color=ff4422]mayor[/color].").scallback(mayor.animate.bind(mayor.HEAD, "default")))
			dlg.add_line(dlg.ml("if you did want to stop me, you'd need to get in the [color=ff4422]factory[/color].").scallback(mayor.a_larm.bind("finger")))
			dlg.add_line(dlg.ml("but it's [color=ff4422]locked[/color].").scallback(mayor.a_larm.bind("up")))
			dlg.add_line(dlg.ml("and the key is in my apartment. [color=ff4422]red text[/color].").scallback(mayor.a_larm.bind("hip")))
			dlg.add_line(dlg.ml("to enter my apartment, you need the [color=ff4422]key to my apartment[/color]."))
			dlg.add_line(dlg.ml("[color=ff4422]good luck[/color]."))

	if dlg.is_empty():
		await Math.timer(1.0)
		return
	await dlg.speak_choice()
