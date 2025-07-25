extends Node2D

const BATTLE_LOAD = preload("res://scenes/tech/scn_battle.tscn")

@onready var mayor := $"../../Other/Mayor"
@onready var dark_hole: Sprite2D = $DarkHole
@onready var skary: Sprite2D = $Skary
@onready var spawners := get_tree().get_nodes_in_group(&"thug_spawners")

@export var greg: PlayerOverworld
@export var modul: ColorContainer

var dlg := DialogueBuilder.new()


func _ready() -> void:
	$DoorInspect.inspected.connect(_door)
	# if youre wondering the mayor is positioned in res://scenes/rooms/town/east_intro_cutscene.gd
	mayor.inspected.connect(_mayor_post_intro)
	#DEBUG
	#_start_battle()


func _door() -> void:
	dlg.clear()
	var inv := ResMan.get_character("greg").inventory
	var end := false
	if &"key_youthcentre" in inv:
		dlg.al("you try the purple key.")
		dlg.al("the keyhole is way too spacious for it.")
		dlg.al("you jangle the key around the hole.").scallback(func() -> void:
			SND.play_sound(preload("res://sounds/biking_bell.ogg"), {pitch_scale = 0.5})
		)
	elif &"explosive_soap" in inv:
		greg.animate("walk_up")
		dlg.al("you apply the explosive soap to the keyhole.")
		inv.erase(&"explosive_soap")
		dlg.set_char("mayor").al("there we go, son! you found something we can use!").scallback(func() -> void:
			mayor.animate(mayor.HEAD, "backward")
		)
		dlg.al("thanks for letting us in. i was really starting to think i'd be stranded here.").scallback(func() -> void:
			var tw := create_tween()
			greg.animate("walk_left")
			tw.tween_property(mayor, "global_position", dark_hole.global_position + Vector2(10, 7), 1.0)
			tw.parallel().tween_property(greg, ^"global_position", dark_hole.global_position - Vector2(10, -7), 1.0)
			tw.tween_callback(greg.animate.bind("walk_right"))
		)
		dlg.al("now, all that's left is to blow this damn door.").scallback(func() -> void:
			mayor.animate(mayor.HEAD, "dark")
		)
		end = true
	else:
		dlg.al("it's truly locked...")
		dlg.al("it'd do good to have a key here.")
	SOL.dialogue_d(dlg.get_dial())
	if end:
		await SOL.dialogue_closed
		_open_door_cutscene()


var yct := false
func _mayor_post_intro() -> void:
	var inv := ResMan.get_character("greg").inventory
	dlg.reset().set_char("mayor")
	if &"mafia_house" in DAT.get_data(&"visited_rooms", []):
		dlg.al("son, i've been thinking.")
		dlg.al("we should [color=ff4422]blow up[/color] the door.")
		dlg.al("we're gonna need something [color=ff4422]good[/color]. something [color=ff4422]better[/color].")
		dlg.al("[color=ff4422]better[/color] than those lousy [color=ff4422]firecrackers[/color].")
		dlg.al("i'm sure you can supply a good [color=ff4422]egshploshive[/color] from somewhere.")
		dlg.al("i'm censoring the word to not get [color=ff4422]demonised[/color].")
	elif &"key_youthcentre" in inv:
		if not yct:
			dlg.al("son... that doesn't look like the right key.")
			dlg.al("i'm incredibly disappointed in you. do [color=ff4422]better[/color].").scallback(func() -> void:
				mayor.animate(mayor.HEAD, "default", 1.0, Vector2(3, 0))
			)
			dlg.al("that key might get you into the [color=ff4422]baby club[/color]...").scallback(func() -> void:
				mayor.animate(mayor.HEAD, "default", 2.0, Vector2(3, 0))
			)
			dlg.al("...or maybe even the [color=ff4422]youth center[/color].").scallback(func() -> void:
				mayor.animate(mayor.HEAD, "default", 0.0, Vector2(0, 0))
			)
			yct = true
		else:
			dlg.al('"where is the youth center?" he asks.').scallback(func() -> void:
				mayor.animate(mayor.HEAD, "dark")
			)
			dlg.al('[color=ff4422]"next to the skate park,"[/color] i reply.')
	elif DAT.get_data(&"mayor_ladder_actieve", false):
		dlg.al("you must [color=ff4422]%s[/color]." % ("clim" + ["bp", "pb", "p", "bb", ""].pick_random()))
	elif &"ladder" in inv:
		dlg.al("are you happy to see me, or is that a [color=ff4422]ladder[/color] in your pockets...")
		dlg.al("huh? which window to use it under?")
		dlg.al("son... back in my day...").scallback(func() -> void:
			mayor.animate(mayor.HEAD, "dark")
		)
		dlg.al("we went and interacted with our ladders under [color=ff4422]every window[/color] to find the right one.")
		dlg.al("go walk the walk, son!").scallback(func() -> void:
			mayor.animate(mayor.HEAD, "default")
			mayor.a_larm("finger")
		)
	else:
		dlg.al("well, son, didja find the key?")
		dlg.al("the key to my [color=ff4422]apartment[/color]...")
		dlg.al("the key to the [color=ff4422]factory[/color] is in there.")
	await dlg.speak_choice()
	mayor.a_default()


func _open_door_cutscene() -> void:
	DAT.capture_player("cutscene")
	await Math.timer(0.2)
	var x := SOL.vfx("explosion", dark_hole.global_position, {parent = dark_hole})
	dark_hole.show()
	skary.show()
	SND.play_song("", 99)
	await Math.timer(0.1)
	x.queue_free()
	await Math.timer(1.5)
	dlg.reset().set_char("mayor")
	dlg.al("by the way, son.")
	dlg.al("you took so long, i didn't even think you'd make it back here.")
	dlg.al("i guess i got a little impatient...")
	await dlg.speak_choice()
	var tw := create_tween()
	tw.tween_property(modul, ^"color", Color(0.321, 0.844, 1.0), 2.0)
	tw.parallel().tween_property(skary.material, "shader_parameter/modulate_a", 1.0, 3.0)
	tw.parallel().tween_property(get_viewport().get_camera_2d(), ^"global_position", dark_hole.global_position, 2.5)
	await tw.finished
	dlg.reset().set_char("mayor")
	dlg.al("i opened the portal to the [color=ff4422]spirit world[/color] just a little bit.")
	dlg.al("let's welcome the new populace of my [color=ff4422]town[/color] together, why not?")
	await dlg.speak_choice()
	SND.play_song("spboss", 0.7)
	SND.play_sound(preload("res://sounds/skating/s6.ogg"))
	tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(greg, ^"global_position", greg.global_position - Vector2(20, 0), 0.3)
	tw.parallel().tween_property(mayor, ^"global_position", mayor.global_position + Vector2(20, 0), 0.3)
	_start_battle()


func _start_battle() -> void:
	for f in spawners:
		f.queue_free()
	DAT.capture_player("cutscene")
	var battle := BATTLE_LOAD.instantiate()
	battle.own_scene = false
	battle._option_init({battle_info = preload("res://resources/battle_infos/mayor_fight.tres")})
	battle.z_index = 99
	add_child(battle)
	battle.ui.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(battle.ui, "modulate:a", 1.0, 2.0)
	battle.global_position = dark_hole.global_position
	var en := BattleEnemy.new()
	en.add_child(Sprite2D.new())
	en.load_character(&"mayor")
	battle.add_actor(en, Battle.Teams.ENEMIES)
