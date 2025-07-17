class_name PoliceStation extends Room

const BountyBoard = preload("res://scenes/gui/scr_bounty_board.gd")

@onready var popo1 := $Npcs/Popo1 as OverworldCharacter
@onready var popo2 := $Npcs/Popo2 as OverworldCharacter

#var bounty: Dictionary[StringName, int]
const TRACKED_BOUNTIES := {
	&"thugs": {
		&"catches": 40,
		&"description": """these criminals are pissing me off... loitering... smoking... smelling... order must be restored in our town! destroy 40 criminals!!""",
	},
	&"stray_animals": {
		&"name": "strays",
		&"catches": 40,
		&"description": """stupid dogs... someone needs to fulfill the job of the pet..pest control service!! annihilate 40 stray pets!!"""
	},
	&"broken_fishermen": {
		&"name": "fishermen",
		&"catches": 40,
		&"description": """annoying fishermen always complain and moan about the fish they lost!! just shut them up already!! eviscerate 40 broken fishermen!!"""
	},
	&"sun_spirit": {
		&"description": """around the lake, rogue spirit attack reports are coming in... it's best to stay away from the area for the time being.""",
		&"hidden": true,
	},
	&"vampire": {
		&"description": """there is talk of a vampire in this town... that's very dangerous!
vampires are unlicensed spirit users, which is illegal. capture this vampire."""
	},
	&"president": {
		&"description": """a citizen claiming to be the president of somewhere is shopping in town. this sounds like a security issue... please remove him."""
	},
}

@onready var cells := Math.child_dict($Cells)
@onready var rage := $SunSpiritRage as Node2D

static var police_standing: int:
	get:
		return DAT.get_data("police_standing", 0)
	set(to):
		DAT.set_data("police_standing", to)


func _ready() -> void:
	super._ready()
	#load_bounties()
	if DAT.seconds < 1 and not LTS.gate_id and not DIR.standalone() and true:
		fulfill_bounty("all") #DEBUG
	setup_cells()
	remove_child(rage)
	SOL.add_ui_child(rage, -1)
	_waiter_setup()


func _on_popo_1_interact_on_interact() -> void:
	var dlg := DialogueBuilder.new().set_char("popo_1")
	var newbounts := false
	for b in TRACKED_BOUNTIES:
		if not is_bounty_fulfilled(b):
			continue
		if DAT.get_data("is_it_known_that_greg_fulfilled_bounty_%s" % b, false):
			continue
		if not newbounts:
			if DAT.get_data("has_talked_with_police", false):
				dlg.add_line(dlg.ml("boom! bountie(s) completed!"))
			else:
				dlg.add_line(dlg.ml("yo! new guy!"))
				dlg.add_line(dlg.ml("we've been following you around for a while..."))
				dlg.add_line(dlg.ml("and you've done a bunch of goodie duties!!"))
				dlg.add_line(dlg.ml("and we have a bunch of rewards available for that."))
			newbounts = true
			SOL.dialogue_d(dlg.get_dial())
		var complete_dial := "bounty_complete_%s" % b
		var reward_path := "res://resources/rewards/bounty/res_%s.tres" % b
		var reward: BattleRewards = null
		if ResourceLoader.exists(reward_path):
			reward = load(reward_path)
		if SOL.dialogue_exists(complete_dial):
			SOL.dialogue(complete_dial)
		if reward:
			reward.grant()
		DAT.set_data("is_it_known_that_greg_fulfilled_bounty_%s" % b, true)
		police_standing += 1
	SOL.dialogue_d(get_greeting())
	if not DAT.get_data("has_talked_with_police", false):
		DAT.set_data("has_talked_with_police", true)
		police_standing += 1
	await SOL.dialogue_closed
	while true:
		var aval_choices := [&"you", &"me", &"bounty", &"east", &"bye"]
		dlg.reset().set_char("popo_1")
		dlg.add_line(dlg.ml("how can \"[font_size=6][font=res://fonts/gregtiny.ttf]the law[/font][/font_size]\" serve you today?")
			.schoices(aval_choices))
		var choice := await dlg.speak_choice()
		if choice == &"bye":
			dlg.reset().set_char("popo_1")
			if police_standing < 3:
				dlg.add_line(dlg.ml("buh bye, citizen!"))
			else:
				dlg.add_line(dlg.ml("buh bye, cutie pie!!"))
			await dlg.speak_choice()
			break
		elif choice == &"you":
			SOL.dialogue("police_about")
			await SOL.dialogue_closed
		elif choice == &"me":
			dlg.reset().set_char("popo_1")
			dlg.add_line(dlg.ml("about you?"))
			if police_standing < 3:
				dlg.add_line(dlg.ml("you're not in the police record..."))
				dlg.add_line(dlg.ml("that must mean you're an awesome, law-abiding citizen..."))
			elif police_standing < 10:
				dlg.add_line(dlg.ml("you're my fabourite guy!!"))
				dlg.add_line(dlg.ml("very good at solving my problems!!"))
				if is_bounty_fulfilled(&"president") or is_bounty_fulfilled(&"vampire"):
					dlg.add_line(dlg.ml("...and others' problems too, i guess?"))
					dlg.add_line(dlg.ml("(those last two bounties on the board...)"))
					dlg.add_line(dlg.ml("(...who put them there?)"))
			await dlg.speak_choice()
		elif choice == &"bounty":
			dlg.reset().set_char("popo_1")
			dlg.add_line(dlg.ml("about the bounty system?"))
			dlg.add_line(dlg.ml("our community is troubled by troublesome troubles."))
			dlg.add_line(dlg.ml("the bounty system is a citizens' initiative!"))
			dlg.add_line(dlg.ml("do a good deed, and get rewarded for it!"))
			dlg.add_line(dlg.ml("the board on the wall over there has more 'inf."))
			await dlg.speak_choice()
		elif choice == &"east":
			dlg.reset().set_char("popo_1")
			dlg.add_line(dlg.ml("the road to the east of town is blocked?"))
			if police_standing < 3:
				dlg.add_line(dlg.ml("there has been a bit of a crime there recently..."))
				dlg.add_line(dlg.ml("a bunch of people were ran over. it was really sad."))
				dlg.add_line(dlg.ml("so you can't go there at the moment..."))
				dlg.add_line(dlg.ml("but if you keep collaborating with us..."))
				dlg.add_line(dlg.ml("we could grant you some access privileges."))
			else:
				if ResMan.get_character("greg").level < 70:
					dlg.add_line(dlg.ml("ahhh... my love for you is strong..., my love..."))
					dlg.add_line(dlg.ml("but not as strong as the enemies in that part of town."))
					dlg.add_line(dlg.ml("please, level up to at least 70..."))
					dlg.add_line(dlg.ml("you don't deserve to be super annihilated."))
				else:
					dlg.add_line(dlg.ml("well, you're not supposed to go there, yet..."))
					dlg.add_line(dlg.ml("but you're just so... awesome!! i'm letting you in."))
					DAT.set_data("popo_blockade_lifted", true)
					dlg.add_line(dlg.ml("the blockade should be lifted now."))


			await dlg.speak_choice()
	#SOL.dialogue("police_main")


func _bounty_interacted() -> void:
	var quests: Array[BountyBoard.QuestListElement] = []
	quests.append(BountyBoard.QuestListElement.new("bounties"))
	for b: StringName in TRACKED_BOUNTIES:
		if TRACKED_BOUNTIES[b].get(&"hidden", false) and not is_bounty_fulfilled(b):
			continue
		var q := BountyBoard.Quest.new(
			b.replace("_", " ") if not &"name" in TRACKED_BOUNTIES[b]
				else TRACKED_BOUNTIES[b][&"name"],
			TRACKED_BOUNTIES[b][&"description"],
			get_bounty_progress(b),
			get_bounty_required(b),
			null,
			true)
		quests.append(q)
	var bb := BountyBoard.make()
	bb.close_requested.connect(func() -> void:
		bb.queue_free()
		DAT.free_player("bounty")
	)
	SOL.add_ui_child(bb)
	bb.fill(quests)
	bb.title_label.text = "bounty board"
	DAT.capture_player("bounty")


func cd(w: Character, c: StringName) -> int:
	return w.get_defeated_character(c)


func get_greeting() -> Dialogue:
	var dlg := DialogueBuilder.new().set_char("popo_1")
	if police_standing <= 3:
		dlg.add_line(dlg.ml("greetings, citizen!"))
	elif police_standing <= 10:
		dlg.add_line(dlg.ml("welcome back, agent!"))
	elif police_standing <= 10000:
		dlg.add_line(dlg.ml("i love you."))
	return dlg.get_dial()


static func get_bounty_required(nomen: StringName) -> int:
	var req := 0
	if not &"catches" in TRACKED_BOUNTIES[nomen]:
		req = 1
	else:
		req = TRACKED_BOUNTIES[nomen][&"catches"]
	return req


static func get_bounty_progress(nomen: StringName) -> int:
	return int(DAT.get_data(nomen + "_fought", 0))


# for external use :) :3 😘
static func is_bounty_fulfilled(nomen: StringName) -> bool:
	return get_bounty_progress(nomen) >= get_bounty_required(nomen)


func fulfill_bounty(nomen: String) -> void:
	if nomen == &"all":
		for i in TRACKED_BOUNTIES:
			fulfill_bounty(i)
		return
	DAT.set_data(nomen + "_fought", get_bounty_required(nomen))
	#bounty[nomen] = (BOUNTY_CATCHES[nomen] if nomen in BOUNTY_CATCHES else 1)


func setup_cells() -> void:
	if not DAT.get_data("trash_guy_inspected", false):
		cells["trash_guy"].queue_free()

	for i in TRACKED_BOUNTIES:
		if i in cells and not is_bounty_fulfilled(i):
			cells[i].queue_free()

	if is_bounty_fulfilled("thugs"):
		$Cells/Thugs/ThugInspect.inspected.connect(
			func():
			if not get_meta("thug_inspected", false):
				SOL.dialogue("insp_cell_thugs_1")
				set_meta("thug_inspected", true)
				return
			SOL.dialogue(str("insp_cell_thugs_2_",
			"enabled" if DAT.get_data("hunks_enabled", false) else "disabled")))
	if is_bounty_fulfilled("sun_spirit"):
		$Cells/SunSpirit/SunSpiritInspect.inspected.connect(art_sun_spirit_rage)
	if is_bounty_fulfilled("vampire"):
		if not DAT.get_data("got_ash_bucket", false):
			$Cells/Vampire/VampireInspect.inspected.connect(func():
				SOL.dialogue_closed.connect(func():
					if SOL.dialogue_choice == "yes":
						$Cells/Vampire/Sprite2D.hide()
						DAT.grant_item("ash_bucket")
						DAT.set_data("got_ash_bucket", true)
						$Cells/Vampire/VampireInspect.key = "vampire_cell_empty"
						SOL.dialogue_choice = ""
				, CONNECT_ONE_SHOT)
			)
		else:
			$Cells/Vampire/VampireInspect.key = "vampire_cell_empty"
			$Cells/Vampire/Sprite2D.hide()

	if police_standing < 1:
		popo2.default_lines.append_array(["police_nobounties", "police_nobounties_2"])


# this is source code poetry
func art_sun_spirit_rage()->void:{false:func():rage.show();var twe:=\
create_tween();rage.get_child(1).modulate.a=0.0;twe.tween_property(rage.\
get_child(1),"modulate:a",1.0,0.4);SND.play_song("");SND.play_sound(preload\
("res://sounds/spirit/solar/flare.ogg"),{"pitch_scale":0.5,"volume":-10});SOL.\
dialogue("insp_sun_spirit_rage_1");DAT.set_data("suspirit_inspected",true);SOL.\
dialogue_closed.connect(func():SOL.dialogue("insp_sun_spirit_rage_2");rage.\
get_child(1).queue_free();SOL.dialogue_closed.connect(func():var tw:=\
create_tween();tw.tween_property(rage,"modulate:a",0.0,2.0);SND.play_song(
"police"),CONNECT_ONE_SHOT),CONNECT_ONE_SHOT)}.get(DAT.get_data(
"suspirit_inspected",false),func():SOL.dialogue("insp_sun_spirit")).call()


func _waiter_setup() -> void:
	var waiter: OverworldCharacter = $Npcs/TheWaiter
	var lines: Array[StringName] = []
	for i in range(1, 5 + 1):
		lines.append(&"police_waiter_mid_" + str(i))
	if DAT.get_data("greenhouses_eaten", 0) > 0:
		lines.append(&"police_waiter_grenhouse")
	if randf() < 0.2:
		lines.append(&"police_waiter_fish")
	waiter.default_lines.append(&"police_waiter_1")
	waiter.default_lines.append(lines.pick_random())
	waiter.default_lines.append(&"police_waiter_2")
