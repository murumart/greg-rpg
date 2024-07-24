class_name PoliceStation extends Room

@onready var popo1 := $Npcs/Popo1 as OverworldCharacter
@onready var popo2 := $Npcs/Popo2 as OverworldCharacter

var bounty := {}
const TRACKED_BOUNTIES := ["thugs", "stray_animals", "broken_fishermen", "sun_spirit", "president", "vampire", "circus"]
#var thugs := ["chimney", "well", "shopping_cart", "kor_sten", "benthon", "moron", "stabbing_fella"]
#var broken := ["broken_fisherman", "not_fish", "sopping"]
#var animals := ["mole", "rainbird", "stray_pet", "wild_lizard"]
const BOUNTY_CATCHES := {
	"thugs": 40,
	"stray_animals": 40,
	"broken_fishermen": 40,
}

@onready var cells := Math.child_dict($Cells)

@onready var rage := $SunSpiritRage as Node2D


func _ready() -> void:
	super._ready()
	load_bounties()
	if DAT.seconds < 1 and not LTS.gate_id: fulfill_bounty("all") #DEBUG
	setup_cells()
	remove_child(rage)
	SOL.add_ui_child(rage, -1)
	_waiter_setup()


func _exit_tree() -> void:
	pass


func _on_popo_1_interact_on_interact() -> void:
	var newbounts := false
	for b in TRACKED_BOUNTIES:
		if is_bounty_fulfilled(b):
			if not DAT.get_data("fulfilled_bounty_%s" % b, false):
				if not newbounts:
					SOL.dialogue("bounty_complete_pre" if DAT.get_data(
						"has_talked_with_police", false)
							else "bounty_complete_pre_first_interaction")
					newbounts = true
				var complete_dial := ("bounty_complete_%s" % b) as String
				var reward_path := (
					"res://resources/rewards/bounty/res_%s.tres" % b) as String
				var reward: BattleRewards = null
				if ResourceLoader.exists(reward_path):
					reward = load(reward_path)
				if complete_dial in SOL.dialogue_box.dialogues_dict:
					SOL.dialogue(complete_dial)
				if reward:
					reward.grant()
				DAT.set_data("fulfilled_bounty_%s" % b, true)
				DAT.incri("police_standing", 1)
	SOL.dialogue(get_greeting())
	SOL.dialogue("police_main")
	if DAT.get_data("police_standing", 0) < 1:
		DAT.set_data("police_standing", 1)
		DAT.set_data("police_sitting", 0)
	DAT.set_data("has_talked_with_police", true)


func _bounty_interacted() -> void:
	get_bounty_info()
	SOL.dialogue("bounty_board")


func load_bounties() -> void:
	bounty["thugs"] = int(DAT.get_data("thugs_fought", 0))
	bounty["stray_animals"] = int(DAT.get_data("stray_animals_fought", 0))
	bounty["broken_fishermen"] = int(DAT.get_data("broken_fishermen_fought", 0))
	bounty["sun_spirit"] = int(DAT.get_data("solar_protuberance_defeated", false))
	bounty["vampire"] = int(DAT.get_data("vampire_defeated", false))
	bounty["president"] = int(DAT.get_data("president_defeated", false))
	bounty["circus"] = int(DAT.get_data("circus_defeated", false))


func cd(w: Character, c: StringName) -> int:
	return w.get_defeated_character(c)


func get_bounty_info() -> void:
	var choices: PackedStringArray = ["exit"]
	choices.append_array([
		"thugs","stryanmls","brknfishr","vampire","president"])
	SOL.dialogue_box.dial_concat("bounty_board", 3, [
		bounty.get("thugs", 0),
		BOUNTY_CATCHES["thugs"]
	])
	SOL.dialogue_box.dial_concat("bounty_board", 6, [
		bounty.get("stray_animals", 0),
		BOUNTY_CATCHES["stray_animals"]
	])
	SOL.dialogue_box.dial_concat("bounty_board", 9, [
		bounty.get("broken_fishermen", 0),
		BOUNTY_CATCHES["broken_fishermen"]
	])
	if is_bounty_fulfilled("sun_spirit"):
		choices.append("sunspirit")
	SOL.dialogue_box.dial_concat("bounty_board", 12, [
		" not " if not is_bounty_fulfilled("sun_spirit") else " "
	])
	SOL.dialogue_box.dial_concat("bounty_board", 15, [
		" not " if not is_bounty_fulfilled("president") else " "
	])
	SOL.dialogue_box.dial_concat("bounty_board", 18, [
		" not " if not is_bounty_fulfilled("circus") else " "
	])
	SOL.dialogue_box.dial_concat("bounty_board", 21, [
		" not " if not is_bounty_fulfilled("vampire") else " "
	])
	SOL.dialogue_box.adjust("bounty_board", 0, "choices", choices)


func get_greeting() -> String:
	var standing := DAT.get_data("police_standing", 0) as int
	if Math.inrange(standing, 0, 2):
		return "police_greeting"
	elif Math.inrange(standing, 3, 5):
		return "police_greeting_happy"
	return "police_greeting"


func is_bounty_fulfilled(nomen: String) -> bool:
	return bounty[nomen] >= (BOUNTY_CATCHES[nomen] if nomen in BOUNTY_CATCHES else 1)


# for external use :) :3 😘
static func is_bounty_fulfilled_static(nomen: String) -> bool:
	return int(DAT.get_data(nomen + "_fought", 0)) >= BOUNTY_CATCHES[nomen]


func fulfill_bounty(nomen: String) -> void:
	if nomen == "all":
		for i in TRACKED_BOUNTIES:
			fulfill_bounty(i)
		return
	bounty[nomen] = (BOUNTY_CATCHES[nomen] if nomen in BOUNTY_CATCHES else 1)


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
