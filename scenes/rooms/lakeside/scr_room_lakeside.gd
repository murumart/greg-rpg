extends Room

@onready var canvas_modulate: ColorContainer = $CanvasModulateGroup/FishWarning
@onready var spawners := get_tree().get_nodes_in_group("thug_spawners")
@onready var fisherwoman: OverworldCharacter = $Buildings/Pier/Fisherwoman
@onready var fast_guy: OverworldCharacter = $Areas/FastGuy


func _ready() -> void:
	super._ready()
	DAT.set_data("lake_visited", true)
	_fish_victim_setup()
	_car_scared_setup()
	_fisherwoman_setup()

	fast_guy.inspected.connect(DAT.set_data.bind("fast_guy_fought", true))
	if DAT.get_data("fast_guy_fought", false):
		fast_guy.queue_free()

	if PoliceStation.is_bounty_fulfilled("broken_fishermen"):
		spawners.map(func(a): a.queue_free())


func _on_pole_interacted() -> void:
	SOL.dialogue("fisherwoman_pole_tutorial")
	SOL.dialogue_closed.connect(func():
		if SOL.dialogue_choice == &"nvm":
			return
		SND.play_song("")
		LTS.level_transition("res://scenes/fishing/scn_fishing_minigame.tscn")
		, CONNECT_ONE_SHOT)


func _on_enemy_encounter_area_body_entered(_body: Node2D) -> void:
	create_tween().tween_property(canvas_modulate, "color", Color(0.592, 0.93, 1.0), 0.4)


func _on_enemy_encounter_area_body_exited(_body: Node2D) -> void:
	create_tween().tween_property(canvas_modulate, "color", Color.WHITE, 0.4)


func _fish_victim_setup() -> void:
	var fish_victim := $Areas/FishVictim as OverworldCharacter
	if DAT.get_data("sunset_triggered", false):
		fish_victim.queue_free()
		return
	fish_victim.inspected.connect(func() -> void:
		if (&"fish_victim_bootful" in fish_victim.default_lines
			or &"fish_victim_bootless_again" in fish_victim.default_lines
		) and ResMan.get_character("greg").armour != &"rubber_boots":
			fish_victim.default_lines = [&"fish_victim_bootless_again"]
		elif ResMan.get_character("greg").armour != &"rubber_boots":
			fish_victim.default_lines = [&"fish_victim_bootless"]
		elif &"fish_victim_bootless" in fish_victim.default_lines:
			if ResMan.get_character("greg").armour == &"rubber_boots":
				fish_victim.default_lines = [&"fish_victim_bootful"]
		elif &"fish_victim_bootless_again" in fish_victim.default_lines:
			fish_victim.default_lines = [&"fish_victim_defeat"]
		elif &"fish_victim_defeat" in fish_victim.default_lines:
			pass
		else:
			if DAT.get_data("fish_fought", false):
				fish_victim.default_lines = [&"fish_victim_after_fight", &"fish_victim_3"]
	)


func _car_scared_setup() -> void:
	if not DAT.get_data("car_scared_overrun", false):
		$Fishermen/Fisherman33.queue_free()


func _fisherwoman_setup() -> void:
	if DAT.get_data("fisherwoman_violently", false):
		fisherwoman.queue_free()
		return
	if DAT.get_data("fisherwoman_fought", false) and Math.inrange(ResMan.get_character("greg").level, 0, 70):
		fisherwoman.queue_free()
		return


var _flower_prog := 0
func _on_fisherwoman_inspected() -> void:
	var dbox := SOL.dialogue_box as DialogueBox
	fisherwoman.enter_a_state_of_conversation()
	var dlg := DialogueBuilder.new().set_char("fisherwoman")
	if DAT.get_data("fisherwoman_fought", false):
		if not DAT.get_data("fisherwoman_opened", false):
			dlg.add_line(dlg.ml("oh... it's you."))
			dlg.add_line(dlg.ml("..."))
			dlg.add_line(dlg.ml("you're not them."))
			dlg.add_line(dlg.ml("i think we might be more similar than i first thought."))
			dlg.add_line(dlg.ml("..."))
			dlg.add_line(dlg.ml("...do you remember..."))
			dlg.add_line(dlg.ml("...who you were before?"))
			dlg.add_line(dlg.ml("..."))
			dlg.add_line(dlg.ml("...").semotion("brood"))
			dlg.add_line(dlg.ml("nevermind. pretend i didn't say anything."))
			DAT.set_data("fisherwoman_opened", true)
		else:
			dlg.add_line(dlg.ml("the fishing pole is over there."))
		await dlg.speak_choice()
		return
	var greeting := "hola, amigo. sup?"
	if not DAT.get_data("fisherwoman_introduced", false):
		DAT.set_data("fisherwoman_introduced", true)
		dlg.add_line(dlg.ml("hey, check out this huge fish i caught."))
		dlg.add_line(dlg.ml("the besties are gonna love it."))
		dlg.clear_char().add_line(dlg.ml("(she shows you the huge fish she caught.)"))
		greeting = "so, what brings you here, buddy?"
		await dlg.speak_choice()
	while true:
		var aval_choices := [&"you", &"me", &"fishing", &"bye"]
		if is_instance_valid(SND.current_song_player):
			SND.current_song_player.volume_db = 0
		if DAT.get_data("fishings_finished", 0) > 0:
			aval_choices.insert(2, &"lures")
		if DAT.get_data("fishings_finished", 0) > 1:
			aval_choices.insert(3, &"flower")
		if _flower_prog > 0:
			aval_choices.erase(&"you")
			aval_choices.erase(&"me")
		if _flower_prog > 1:
			aval_choices.erase(&"fishing")
			aval_choices.erase(&"lures")
			greeting = "..."
			if is_instance_valid(SND.current_song_player):
				SND.current_song_player.volume_db = -10
		if _flower_prog > 2:
			aval_choices.erase(&"bye")
			if is_instance_valid(SND.current_song_player):
				SND.current_song_player.volume_db = -20
		if _flower_prog > 3:
			if is_instance_valid(SND.current_song_player):
				SND.current_song_player.volume_db = -80
		dlg.clear().set_char("fisherwoman")
		dlg.add_line(dlg.ml(greeting).schoices(aval_choices))
		var choice := await dlg.speak_choice()
		if choice == &"bye":
			break
		elif choice == &"you":
			dlg.reset().set_char("fisherwoman")
			dlg.add_line(dlg.ml("like, who i am?"))
			dlg.add_line(dlg.ml("hahaha! who knows!"))
			dlg.add_line(dlg.ml("i discovered fishing one day..."))
			dlg.add_line(dlg.ml("and life has been good ever since."))
			await dlg.speak_choice()
		elif choice == &"me":
			dlg.reset().set_char("fisherwoman")
			dlg.add_line(dlg.ml("about you?"))
			dlg.add_line(dlg.ml("i don't know you, dude... why not introduce yourself?"))
			dlg.add_line(dlg.ml("...nothing? okay, i know that feel, bro..."))
			await dlg.speak_choice()
		elif choice == &"fishing":
			dlg.reset().set_char("fisherwoman")
			if DAT.get_data("fishings_finished", 0) <= 0:
				dlg.add_line(dlg.ml("you wish to fish? hnnng, same, bestie."))
				dlg.add_line(dlg.ml("that fishing pole over there is free to use!"))
				dlg.add_line(dlg.ml("knock yourself out, dude."))
				dlg.add_line(dlg.ml("check out the new spirit-powered tech it has..."))
				dlg.add_line(dlg.ml("will be super illegal once legislation catches up!"))
				dlg.add_line(dlg.ml("but you can, like, catch so many fish with one cast."))
			else:
				dlg.add_line(dlg.ml("here come your fishing scores, dude:"))
				dlg.add_line(dlg.ml("most points you've gotten: [color=YELLOW]%s[/color]!" % DAT.get_data("fishing_high_score")))
				dlg.add_line(dlg.ml("the deepest you've reached is [color=YELLOW]%s meters[/color]!" % roundi(DAT.get_data("fishing_max_depth", 0.0) * 0.01)))
				dlg.add_line(dlg.ml("and you've caught [color=YELLOW]%s[/color] fish all-in-all!" % DAT.get_data("fish_caught")))
			await dlg.speak_choice()
		elif choice == &"lures":
			dlg.reset().set_char("fisherwoman")
			dlg.add_line(dlg.ml("that's right, bestie: there's different lures for you to use!"))
			dlg.add_line(dlg.ml("each works differently, so you gotta, like, learn..."))
			dlg.add_line(dlg.ml("you can buy one from the kid next to the road..."))
			dlg.add_line(dlg.ml("...or you can totally just beat up other fishermen..."))
			dlg.add_line(dlg.ml("...until they drop their lures instead."))
			dlg.add_line(dlg.ml("use the lure item on yourself before going fishing!"))
			dlg.add_line(dlg.ml("it'll last for one go at fishing."))
			await dlg.speak_choice()
		elif choice == &"flower":
			dlg.reset().set_char("fisherwoman").set_emo("brood")
			if _flower_prog == 0:
				if is_instance_valid(SND.current_song_player):
					SND.current_song_player.volume_db -= 6
				dlg.add_line(dlg.ml("..."))
				dlg.add_line(dlg.ml("i deal in fish, not [color=%s]flowers[/color]." % Math.FLOWERCOLOR))
				dlg.add_line(dlg.ml("do you understand?"))
				_flower_prog += 1
			elif _flower_prog == 1:
				if is_instance_valid(SND.current_song_player):
					SND.current_song_player.volume_db -= 6
				dlg.add_line(dlg.ml("..."))
				dlg.add_line(dlg.ml("that \"life\" is behind me."))
				dlg.add_line(dlg.ml("what did they expect?"))
				_flower_prog += 1
			elif _flower_prog == 2:
				if is_instance_valid(SND.current_song_player):
					SND.current_song_player.volume_db -= 12
				dlg.add_line(dlg.ml("..."))
				dlg.add_line(dlg.ml("...i'm warning you."))
				dlg.add_line(dlg.ml("we can talk about fish all day, dude."))
				dlg.add_line(dlg.ml("you don't have to bring this up."))
				dlg.add_line(dlg.ml("forget about it, okay?"))
				_flower_prog += 1
				await dlg.speak_choice()
				break
			elif _flower_prog == 3:
				if is_instance_valid(SND.current_song_player):
					SND.current_song_player.volume_db -= 24
				dlg.add_line(dlg.ml("why..."))
				dlg.add_line(dlg.ml("why do you care about the [color=%s]flower[/color] so much?" % Math.FLOWERCOLOR))
				_flower_prog += 1
			elif _flower_prog == 4:
				if is_instance_valid(SND.current_song_player):
					SND.current_song_player.volume_db = -80
				dlg.add_line(dlg.ml("..."))
				dlg.add_line(dlg.ml("......").stext_speed(0.5))
				await dlg.speak_choice()
				DAT.set_data("fisherwoman_fought", true)
				LTS.enter_battle(preload("res://resources/battle_infos/fisherwoman_fight.tres"))
				break

			await dlg.speak_choice()
