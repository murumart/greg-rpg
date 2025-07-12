class_name PoliceStation extends Room

const BountyBoard = preload("res://scenes/gui/scr_bounty_board.gd")

@onready var popo1 := $Npcs/Popo1 as OverworldCharacter
@onready var popo2 := $Npcs/Popo2 as OverworldCharacter

#var bounty: Dictionary[StringName, int]
const TRACKED_BOUNTIES := {
	&"thugs": {
		&"catches": 40,
		&"description": """there are plenty of petty criminals running around town.
catch them! lock em up! put them in jail!""",
	},
	&"stray_animals": {
		&"name": "strays",
		&"catches": 40,
		&"description": """some pet owners really need to keep their pets inside...
as long as they don't, they're a safety issue for you to solve."""
	},
	&"broken_fishermen": {
		&"name": "fishermen",
		&"catches": 40,
		&"description": """some people really can't handle losing their loved ones.
others can't handle losing a fish off their hook."""
	},
	&"sun_spirit": {
		&"description": """rumor has it that a rogue spirit from the sun is in the forest somewhere.
it attacks on sight... but surely you can take care of it?""",
		&"hidden": true,
	},
	&"president": {
		&"description": """a citizen claiming to be the president of some- where is shopping in town.
this sounds like a security issue... please remove him."""
	},
	&"vampire": {
		&"description": """there is talk of a vampire in this town... that's horrible!
vampires are unlicensed spirit users, which is illegal."""
	},
}

@onready var cells := Math.child_dict($Cells)
@onready var rage := $SunSpiritRage as Node2D


func _ready() -> void:
	super._ready()
	#load_bounties()
	if DAT.seconds < 1 and not LTS.gate_id and not DIR.standalone() and false:
		fulfill_bounty("all") #DEBUG
	setup_cells()
	remove_child(rage)
	SOL.add_ui_child(rage, -1)
	_waiter_setup()


func _on_popo_1_interact_on_interact() -> void:
	var newbounts := false
	for b in TRACKED_BOUNTIES:
		if not is_bounty_fulfilled(b):
			continue
		if DAT.get_data("is_it_known_that_greg_fulfilled_bounty_%s" % b, false):
			continue
		if not newbounts:
			SOL.dialogue("bounty_complete_pre" if DAT.get_data(
				"has_talked_with_police", false)
					else "bounty_complete_pre_first_interaction")
			newbounts = true
		var complete_dial := "bounty_complete_%s" % b
		var reward_path := "res://resources/rewards/bounty/res_%s.tres" % b
		var reward: BattleRewards = null
		if ResourceLoader.exists(reward_path):
			reward = load(reward_path)
		if complete_dial in SOL.dialogue_box.dialogues_dict:
			SOL.dialogue(complete_dial)
		if reward:
			reward.grant()
		DAT.set_data("is_it_known_that_greg_fulfilled_bounty_%s" % b, true)
		DAT.incri("police_standing", 1)
	SOL.dialogue(get_greeting())
	SOL.dialogue("police_main")
	if DAT.get_data("police_standing", 0) < 1:
		DAT.set_data("police_standing", 1)
		DAT.set_data("police_sitting", 0)
	DAT.set_data("has_talked_with_police", true)


func _bounty_interacted() -> void:
	var quests: Array[BountyBoard.Quest] = []
	for b: StringName in TRACKED_BOUNTIES:
		if TRACKED_BOUNTIES[b].get(&"hidden", false) and not is_bounty_fulfilled(b):
			continue
		var q := BountyBoard.Quest.new(
			b.replace("_", " ") if not &"name" in TRACKED_BOUNTIES[b]
				else TRACKED_BOUNTIES[b][&"name"],
			TRACKED_BOUNTIES[b][&"description"],
			get_bounty_progress(b),
			get_bounty_required(b))
		quests.append(q)
	var bb := BountyBoard.make(quests)
	bb.close_requested.connect(func() -> void:
		bb.queue_free()
		DAT.free_player("bounty")
	)
	SOL.add_ui_child(bb)
	bb.title_label.text = "bounty board"
	DAT.capture_player("bounty")


func cd(w: Character, c: StringName) -> int:
	return w.get_defeated_character(c)


func get_greeting() -> String:
	var standing := DAT.get_data("police_standing", 0) as int
	if Math.inrange(standing, 0, 2):
		return "police_greeting"
	elif Math.inrange(standing, 3, 5):
		return "police_greeting_happy"
	return "police_greeting"


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

	if DAT.get_data("police_standing", 0) < 1:
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
