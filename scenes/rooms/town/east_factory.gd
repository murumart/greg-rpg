extends Node2D

const BATTLE_LOAD = preload("res://scenes/tech/scn_battle.tscn")
const CameraType = preload("res://scenes/tech/scr_camera.gd")

@onready var mayor := $%Mayor
@onready var dark_hole: Sprite2D = $DarkHole
@onready var skary: Sprite2D = $Skary
@onready var spawners := get_tree().get_nodes_in_group(&"thug_spawners")
@onready var burn_mark: Sprite2D = $BurnMark

@export var greg: PlayerOverworld
@export var modul: ColorContainer
@export var camera: CameraType

var dlg := DialogueBuilder.new()


func _ready() -> void:
	$DoorInspect.inspected.connect(_door)
	# if youre wondering the mayor is positioned in res://scenes/rooms/town/east_intro_cutscene.gd
	mayor.inspected.connect(_mayor_post_intro)
	if DAT.get_data(&"mayor_fought", false):
		dark_hole.show()
		skary.hide()
		mayor.hide()
		for s in spawners:
			if is_instance_valid(s):
				s.erase_thugs_from_mem()
				s.queue_free()
		mayor.set_global_position.call_deferred(Vector2(9999, 9999))
	else:
		burn_mark.hide()
	#DEBUG
	#else: _open_door_cutscene(true)


func _door() -> void:
	dlg.clear()
	var inv := ResMan.get_character("greg").inventory
	var end := false
	if DAT.get_data(&"mayor_fought", false):
		LTS.gate_id = &"east-factory"
		LTS.level_transition(LTS.ROOM_SCENE_PATH % "factory_inside")
		return
	elif &"explosive_soap" in inv:
		greg.animate("walk_up")
		dlg.al("you jam the explosive soap into the keyhole.")
		inv.erase(&"explosive_soap")
		dlg.set_char("mayor").al("there we go, son! you found something we can use!").scallback(func() -> void:
			mayor.animate(mayor.HEAD, "backward")
			SND.play_song("mayor", 1.0, {play_from_beginning = true})
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
	elif &"key_youthcentre" in inv:
		dlg.al("you try the purple key.")
		dlg.al("the keyhole is way too spacious for it.")
		dlg.al("you jangle the key around the hole.").scallback(func() -> void:
			SND.play_sound(preload("res://sounds/biking_bell.ogg"), {pitch_scale = 0.5})
		)
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


func _open_door_cutscene(skip := false) -> void:
	if not skip:
		DAT.capture_player("cutscene")
		await Math.timer(0.2)
		var x := SOL.vfx("explosion", dark_hole.global_position, {parent = dark_hole})
		dark_hole.show()
		skary.material["shader_parameter/modulate_a"] = 0.0
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
	else:
		dark_hole.show()
		skary.material["shader_parameter/modulate_a"] = 0.0
		skary.show()
	var tw := create_tween()
	tw.tween_property(modul, ^"color", Color(0.321, 0.844, 1.0), 2.0)
	tw.parallel().tween_property(skary.material, "shader_parameter/modulate_a", 1.0, 3.0)
	tw.parallel().tween_property(get_viewport().get_camera_2d(), ^"global_position", dark_hole.global_position, 2.5)
	SND.play_song("spboss", 0.7)
	await tw.finished
	if not skip:
		dlg.reset().set_char("mayor")
		dlg.al("i opened the window to the [color=ff4422]spirit world[/color] just a little bit.")
		dlg.al("let's welcome the new populace of my [color=ff4422]town[/color] together, why not?")
		await dlg.speak_choice()
	mayor.animate(mayor.HEAD, "dark", 4.0, Vector2(1, 1))
	mayor.animate(mayor.BODY, "forward", 2.0, Vector2(1, 1))
	mayor.a_leg("walk", 2.0, Vector2(1, 0), 2.0)
	mayor.a_larm("flail", 1.0, Vector2(0, 1), 4.0)
	mayor.a_rarm("hip", 4.0, Vector2(0, 1), 2.0)
	SND.play_sound(preload("res://sounds/skating/s6.ogg"))
	tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(greg, ^"global_position", greg.global_position - Vector2(20, 0), 0.3)
	tw.parallel().tween_property(mayor, ^"global_position", mayor.global_position + Vector2(20, 0), 0.3)
	_start_battle()
	await tw.finished
	battle_mayor.global_position = mayor.global_position


const SPType = preload("res://scenes/characters/battle_enemies/scr_enemy_spirit_portal.gd")
var battle_spiritportal: SPType
var battle_mayor: BattleActor
var battle: Battle
func _start_battle() -> void:
	for f in spawners:
		if is_instance_valid(f): f.queue_free()
	DAT.capture_player("cutscene")
	battle = BATTLE_LOAD.instantiate()
	battle.own_scene = false
	battle.keep_arranging = false
	battle._option_init({battle_info = preload("res://resources/battle_infos/mayor_fight.tres")})
	battle.z_index = 99
	add_child(battle)
	await battle.battle_loaded
	battle_spiritportal = battle.enemies[0]
	battle_spiritportal.died.disconnect(battle._on_actor_died)
	battle_spiritportal.battle = battle # spaghet
	battle_spiritportal.pls_x.connect(_battle_ending)
	battle.ui.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(battle.ui, "modulate:a", 1.0, 2.0).from(0.0)
	battle.global_position = dark_hole.global_position
	battle_mayor = BattleEnemy.new()
	battle_spiritportal.mayor = battle_mayor
	# for animation errorsd
	var sp := Node2D.new()
	battle_mayor.add_child(sp)
	battle_mayor.load_character(&"mayor")
	battle_mayor.payload_post.connect(_mayor_pld_after)
	battle.add_actor(battle_mayor, Battle.Teams.ENEMIES)
	battle_spiritportal.global_position = dark_hole.global_position + Vector2(0, -8)


func _mayor_pld_after(pld: BattlePayload) -> void:
	if is_instance_valid(pld.sender) and pld.sender.actor_name == "tourist" and battle_mayor.character.health > 0:
		dlg.reset().set_char("mayor")
		dlg.al("what the...!!")
		dlg.al("these spirits from the spirit world...")
		dlg.al("one of them just attacked me!")
		dlg.al("they're no better than our ordinary thugs!!!")
		dlg.al("curses for a thousand years!").scallback(func() -> void:
			mayor.animate(mayor.HEAD, "dark", 8.0, Vector2(1, 0))
		)
		dlg.al("well, i just did curse us for a while, i think.").scallback(func() -> void:
			mayor.a_default()
		)
		dlg.al("change of plan, son! we have to close this window!!")
		await dlg.speak_choice()
		battle.message("mayor joins your party!")
		var hp := battle_mayor.character.health
		battle_mayor.fled.emit(battle_mayor)
		battle_mayor.state = battle_mayor.States.DEAD
		battle_mayor.global_position = Vector2(999, 999) # no particals...
		battle_mayor = BattleActor.new()
		battle_mayor.load_character("scooterer")
		battle_mayor.character.health = hp
		battle.add_actor(battle_mayor, Battle.Teams.PARTY)
		battle_mayor.wait = 0
		battle_mayor.payload_post.connect(_mayor_team_pld_after)
		var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(mayor, "global_position", greg.global_position + Vector2(0, 9), 0.4)
		tw.tween_property(battle.camera, ^"global_position", greg.global_position.lerp(dark_hole.global_position, 0.5).floor(), 0.4)
		SND.play_sound(preload("res://sounds/whoosh.ogg"))
		await tw.finished
		await Math.timer(0.1)
		dlg.reset().set_char("scooterer")
		dlg.al("i'm on my scooter now!")
		dlg.al("help me charge up my [color=%s]sp[/color]!" % dlg.SPIRITCOLOR)
		dlg.al("my power [color=%s]scootrev[/color] gives me a good boost!" % dlg.SPIRITCOLOR)
		dlg.al("and after, we can use [color=%s]overscoot[/color] to deal a ton of damage!" % dlg.SPIRITCOLOR)
		dlg.al("you've battled me before, right!? you know how it works, son!")
		dlg.al("if we damage the window enough, it will collapse!!")
		await dlg.speak_choice()
	if battle_mayor.character.health <= 0:
		mayor.rotate(PI / 2)
		mayor.a_default()
		DAT.death_reason = DAT.DeathReasons.MAYOR_DIE
		LTS.to_game_over_screen()


var attakcs := 0
func _mayor_team_pld_after(pld: BattlePayload) -> void:
	if pld.type == pld.Types.ATTACK and pld.sender.actor_name == "greg":
		if attakcs == 0:
			attakcs += 1
			dlg.reset().set_char("scooterer")
			dlg.al("what the...!!")
			dlg.al("i'm on your team, son!! we have to work together!!")
			dlg.al("we have to close the window!!")
			await dlg.speak_choice()
		elif attakcs == 1:
			attakcs += 1
			dlg.reset().set_char("scooterer")
			dlg.al("son... don't make this harder than it needs be...")
			dlg.al("this battle system doesn't have three teams! i have to choose!")
			await dlg.speak_choice()
		else:
			attakcs += 1
			dlg.reset().set_char("scooterer")
			dlg.al("...")
	if battle_mayor.character.health <= 0:
		mayor.rotate(PI / 2)
		mayor.a_default()
		DAT.death_reason = DAT.DeathReasons.MAYOR_DIE
		LTS.to_game_over_screen()


const MenType = preload("res://scenes/vfx/x_menacing.gd")
func _battle_ending() -> void:
	battle.doing = battle.Doings.DONE
	mayor.global_position = greg.global_position + Vector2(0, 9)
	var tw := create_tween()
	tw.tween_property(battle.ui, ^"modulate:a", 0.0, 0.2)
	SND.play_song("")
	await Math.timer(2.5)
	SOL.vfx("xattack", dark_hole.global_position - Vector2(0, 9), {parent = dark_hole})
	await Math.timer(1.1)
	battle_spiritportal.hurt(20882088, Genders.VAST)
	await Math.timer(0.5)
	skary.hide()
	$ShardsTexture/AnimationPlayer.play(&"defa")
	create_tween().tween_property(modul, ^"color", Color(0.849, 0.879, 0.821), 1.0)
	mayor.a_default()
	await Math.timer(4.0)
	dlg.reset().set_char("mayor")
	dlg.al("th... the window was shattered!!")
	dlg.al("could it really have been...")
	dlg.al("well, i have a good feeling about this, son!").scallback(func() -> void:
		var t := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_property(mayor, "global_position", %FinalMayorPos.global_position, 0.5)
	)
	await dlg.speak_choice()
	SND.play_song("bymssc", 0.8)
	tw = create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(modul, ^"color", Color(0.124, 1.0, 0.0), 2.0)
	tw.parallel().tween_property(battle.camera, ^"global_position", battle.camera.global_position - Vector2(0, 20), 2.0)
	$Menace.show()
	var menacing: MenType = $Menace/Menacing
	var menanim: AnimationPlayer = $Menace/AnimationPlayer
	menanim.play(&"descend")
	menanim.queue(&"hover")
	await menanim.animation_changed
	dlg.reset().set_char("mayor")
	dlg.al("there you are, [color=0f0]girl[/color]! i knew that was you!")
	dlg.al("thanks a lot! that window just opened out of nowhere...")
	dlg.al("spirits started pouring out... oh, it was terrible!")
	dlg.al("even with my [color=%s]flower[/color], we had trouble..." % dlg.FLOWERCOLOR)
	dlg.al("well... all's well that ends well.")
	dlg.al("just... what is with that ominous, shadowy look, [color=0f0]girl[/color]?")
	await dlg.speak_choice()
	await Math.timer(1.0)
	dlg.reset().set_char("mayor")
	dlg.al("this is no way to talk to your [color=f42]mayor[/color], [color=0f0]girl[/color].").stext_speed(0.9)
	(dlg.al("i'm going to have to talk to your [color=f42]parents[/color], i'm afraid")
		.stext_speed(0.75)
		.scallback(func() -> void:
			menacing.particles(1.0)
			menanim.stop(true)
			var t := create_tween().set_trans(Tween.TRANS_CUBIC)
			t.tween_interval(0.9)
			t.tween_callback(SND.play_sound.bind(preload("res://sounds/men-01.ogg")))
			t.tween_property(menacing, ^"global_position:x", mayor.global_position.x, 0.25).set_ease(Tween.EASE_OUT)
			t.tween_callback(func() -> void:
				menanim.play("peam")
				modul.color = Color.WHITE
			)
			t.tween_interval(0.35)
			SND.play_song("", 999)
			t.tween_callback(func() -> void:
				camera.global_position = battle.camera.global_position
				camera.make_current()
				camera.add_trauma(1.0)
				camera.shake_trauma_power = 3.0
				SOL.dialogue_box.close()
			)
			t.tween_interval(0.8)
			t.tween_callback(func() -> void:
				SOL.fade_screen(Color(Color.GREEN, 0), Color.GREEN, 0.8, {free_rect = false})
			)
	))
	dlg.speak()
	DAT.set_data("mayor_fought", true)
	await SOL.fade_finished
	burn_mark.show()
	await Math.timer(3.0)
	battle.queue_free()
	mayor.global_position = Vector2(999, 999)
	menacing.global_position = Vector2(999, 999)
	menacing.hide()
	mayor.hide()
	SND.play_song("extremophile", 0.5, {pitch_scale = 0.88})
	SOL.fade_screen(Color.GREEN, Color(Color.GREEN, 0.0), 4.0, {kill_rects = true})
	camera.position = Vector2(0, -9)
	await SOL.fade_finished
	DAT.free_player("cutscene")
