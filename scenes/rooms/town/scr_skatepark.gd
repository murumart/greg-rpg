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
	var dlg := DialogueBuilder.new()
	var aval_choices := [&"bye", &"key", &"skate"]
	dlg.al("yo.").schoices(aval_choices)
	var choice := await dlg.speak_choice()
	dlg.reset()
	if choice == &"bye":
		dlg.al("oy. it's reverse yo.")
		await dlg.speak_choice()
	elif choice == &"key":
		dlg.al("the key to the [color=ff4422]mayor's apartment[/color]...")
		dlg.al("that item is reserved for [color=ff4422]cool skaters[/color] only.")
		dlg.al("please ask again when you're a [color=ff4422]cool skater[/color].")
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
