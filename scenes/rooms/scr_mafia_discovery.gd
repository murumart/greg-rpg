extends Area2D

# that's how mafia works

@onready var mafia_blue: OverworldCharacter = %MafiaBlue
@onready var mafia_yellow: OverworldCharacter = %MafiaYellow
@onready var greg: PlayerOverworld = $"../../Greg"
@onready var lights: Array[PointLight2D]
@onready var radio: Node2D = $"../../Decorations/Radio"
@onready var big_light: PointLight2D = $"../../Decorations/BigLight"
@onready var kid: CharacterBody2D = $"../../Decorations/KidOverworld"

var introed: bool:
	set(to): DAT.set_data("mafia_introed", to)
	get: return DAT.get_data("mafia_introed", false)
var correct_numbers: int:
	set(to): DAT.set_data("mafia_correct_nums", to)
	get: return DAT.get_data("mafia_correct_nums", 0)
var got_boom: int:
	set(to): DAT.set_data("mafia_explosives_claimed", to)
	get: return DAT.get_data("mafia_explosives_claimed", 0)


func _ready() -> void:
	if got_boom <= 0:
		kid.global_position.y = -999
	mafia_blue.inspected.connect(_mafia_blue_interact)
	lights.assign(get_tree().get_nodes_in_group(&"lights"))
	if introed:
		big_light.show()
	else:
		SOL.dialogue("mafia_mumbles_1")


func _mafia_blue_interact() -> void:
	var dlg := DialogueBuilder.new()
	mafia_blue.enter_a_state_of_conversation()
	dlg.set_char("mafia_blue")
	while true:
		var aval_choices := [&"bye", &"work", &"reward"]
		dlg.reset().al('"sup", "buddy". what do you need?').schoices(aval_choices)

		var choice := await dlg.speak_choice()
		if choice == &"bye":
			break
		elif choice == &"work":
			dlg.reset()
			dlg.al("the numbers... the numbers...").schoices(["yes", "no"])
			var c := await dlg.speak_choice()
			if c == &"yes":
				DAT.capture_player("game")
				var lg := await _to_game()

				lg.finished.connect(func(c: int) -> void:
					DAT.free_player("game")
					correct_numbers += c
					lg.queue_free()
					await _after_game()
				)
				break
		elif choice == &"reward":
			dlg.reset()
			if correct_numbers < 20:
				dlg.al("not so fast, pal!")
				dlg.al("we need you to write down at least 20 numbers correctly...")
				dlg.al("...before we can trust you.")
				dlg.al("you have %s so far." % correct_numbers)
			else:
				if got_boom == 0:
					got_boom = 1
					dlg.al("well, you have done a good job writing those numbers.")
					dlg.al("nice work, pal.")
					dlg.al("as a reward, we'll allow you to financially support us.")
					dlg.al("hey, kid!").scallback(func() -> void:
						var tw := create_tween()
						tw.tween_property(kid, ^"position:y", -31, 0.2)
						SOL.vfx("explosion", kid.global_position, {parent = kid})
					)
					dlg.set_char("kid").al("what's up?")
					dlg.set_char("mafia_blue").al("our pal here wants to trade.")
					dlg.al("prepare all the products.")
					dlg.set_char("kid").al("yessir!")
					dlg.set_char("mafia_blue")
				else:
					dlg.al("nice work, pal.")
					dlg.al("now go spend your money on that child over there.")

			await dlg.speak_choice()


func _to_game() -> ListeningGame:
	radio.musicplayer.stop()
	$AudioStreamPlayer.play()
	for l in lights:
		l.hide()
	var lg := ListeningGame.make(
		remap(correct_numbers, 0, 30, 2, 10),
		roundi(remap(correct_numbers, 0, 35, randf_range(1, 1.2), randf_range(3, 5))))
	if not introed:
		lg.tutorialate = true
		await Math.timer(5.0)
	else:
		await Math.timer(1.0)
	SOL.add_ui_child(lg)
	return lg


func _after_game() -> void:
	DAT.capture_player("wait")
	await Math.timer(1.0)
	for l in lights:
		l.show()
	$AudioStreamPlayer.play()
	greg.global_position = %GregPos.global_position
	mafia_blue.global_position = %MafiaPos.global_position
	mafia_yellow.global_position = %MafiaPos.global_position + Vector2(0, -10)
	mafia_blue.set_physics_process(true)
	mafia_yellow.set_physics_process(true)
	mafia_blue.direct_walking_animation(Vector2.RIGHT)
	mafia_yellow.direct_walking_animation(Vector2.RIGHT)
	greg.animate("walk_down")
	await Math.timer(1.0)
	greg.animate("walk_left")
	await Math.timer(0.5)
	DAT.free_player("wait")


func _area_entered() -> void:
	if introed:
		return
	$PointLight2D2.color = Color.GRAY
	DAT.capture_player("cutscene")
	SOL.dialogue("mafia_interrupt")
	mafia_blue.set_physics_process(false)
	mafia_yellow.set_physics_process(false)
	var anim := "walk_right" if mafia_blue.global_position.x - greg.global_position.x < -1 else "walk_left"
	mafia_blue.animated_sprite.play(anim)
	mafia_yellow.animated_sprite.play(anim)
	await SOL.dialogue_closed
	$PointLight2D2.color = Color(0.049, 0.049, 0.047)
	var lg := await _to_game()
	var corrects: int = await lg.finished
	if not introed:
		DAT.set_data("mfia_first_corrects", corrects)
	lg.queue_free()
	await _after_game()
	_after_first()


func _after_first() -> void:
	introed = true
	SOL.dialogue("mafia_after_first")
	await SOL.dialogue_closed
	DAT.free_player("cutscene")
