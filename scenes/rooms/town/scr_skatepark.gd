extends Node2D

@onready var skate_worry := $SkateWorry as OverworldCharacter
@onready var goodness: Node2D = $Goodness
@onready var jack_2 := $Goodness/Jack2 as OverworldCharacter
@onready var kid: CharacterBody2D = $Goodness/KidOverworld
@onready var thug_spawner_4: EnemySpawner = $ThugSpawner4


func _ready() -> void:
	skatepark_setup()


func skatepark_setup() -> void:
	if not PoliceStation.is_bounty_fulfilled("thugs") or DAT.get_data("hunks_enabled", false):
		goodness.queue_free()
		return
	thug_spawner_4.queue_free()
	skate_worry.default_lines.clear()
	if DAT.get_data("hunks_enabled", false):
		skate_worry.default_lines.append_array(["skate_worry_bad", "skate_worry_3"])
	else:
		skate_worry.default_lines.append_array(["skate_worry_good", "skate_worry_3"])
	jack_2.inspected.connect(sk8r_kid_talk)


func sk8r_kid_talk() -> void:
	var gotten: bool = DAT.get_data("got_sk8r_ladder", false)
	var games_finished: int = DAT.get_data("skating_games_finished", 0)
	var highscore: int = DAT.get_data("skating_points_hiscore", 0)
	var dlg := DialogueBuilder.new()
	var aval_choices := [&"key", &"skate", &"bye"]
	dlg.al("yo.").schoices(aval_choices)
	var choice := await dlg.speak_choice()
	dlg.reset()
	if choice == &"bye":
		dlg.al("oy. it's reverse yo.")
		await dlg.speak_choice()
	elif choice == &"key":
		if not gotten:
			if games_finished == 0:
				dlg.al("the key to the [color=ff4422]mayor's apartment[/color]...")
				dlg.al("that item is reserved for [color=ff4422]cool skaters[/color] only.")
				dlg.al("please ask again when you're a [color=ff4422]cool skater[/color].")
				await dlg.speak_choice()
			else:
				var can_get := false

				if highscore < 200000 and not can_get:
					dlg.al("to become [color=ff4422]cool skater's[/color], one must reach a high-score of 200000.")
					var l := dlg.al("[color=ff4422]you[/color] have %s, right now." % highscore)
					if games_finished > 5 and highscore >= 50000:
						l.schoices(["please"])
					if await dlg.speak_choice() == &"please":
						dlg.reset()
						dlg.al("man, you seem desperate...")
						can_get = true
						await dlg.speak_choice()
				else:
					can_get = true

				if can_get:
					dlg.reset().al("i think you've proved yourself a [color=ff4422]cool skaters'[/color].")
					dlg.al("for that, the reward...")
					dlg.al("...")
					dlg.al("i was hoping... well, the key is in use by another guy right now.")
					dlg.al("so i'm just going to give you this ladder to reach his [color=ff4422]apartment[/color].")
					dlg.al("he lives in the ugly-ass housing block to the north of here.")
					dlg.al("you can't miss it.")
					dlg.al("keep [color=ff4422]cool skating[/color] in your life, bro...")
					await dlg.speak_choice()
					DAT.grant_item("ladder")
					DAT.set_data("got_sk8r_ladder", true)
		else:
			#if &"ladder" not in ResMan.get_character("greg").inventory
			dlg.al("you got the ladder, bro... just climb in thru his window.")
			dlg.al("his window is one of them on the housing block to the north of here.")
			await dlg.speak_choice()

	elif choice == &"skate":
		dlg.al("so you want to be a [color=ff4422]cool skaters[/color]...").schoices(["yes", "no"])
		var c := await dlg.speak_choice()
		dlg.reset()
		if c == &"yes":
			dlg.al("very well. here's my skateboard.")
			dlg.al("move with movement keys, jump with %s and tilt with %s in the air."
				% [KeybindsSettings.action_string(&"cancel"), KeybindsSettings.action_string(&"menu")])
			await dlg.speak_choice()
			LTS.level_transition("res://scenes/skating/skating_minigame.tscn")
