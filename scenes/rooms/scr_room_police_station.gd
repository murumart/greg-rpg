extends Room

@onready var popo1 := $Npcs/Popo1 as OverworldCharacter

var bounty := {}
var tracked_bounties := ["thugs", "stray_animals", "broken_fishermen", "sun_spirit", "president", "vampire", "circus"]
var thugs := ["chimney", "well", "shopping_cart", "kor_sten", "abiss", "moron", "stabbing_fella"]
var broken := ["broken_fisherman", "not_fish", "sopping"]
var animals := ["mole", "rainbird", "stray_pet", "wild_lizard"]
const BOUNTY_CATCHES := {
	"thugs": 40,
	"stray_animals": 40,
	"broken_fishermen": 40,
}

@onready var cells := (func():
	var dict := {}
	for c in $Cells.get_children():
		dict[c.name.to_snake_case()] = c
	return dict).call() as Dictionary

@onready var rage := $SunSpiritRage as Node2D


func _ready() -> void:
	super._ready()
	load_bounties()
	if DAT.seconds < 1: fulfill_bounty("all") #debug
	setup_cells()
	remove_child(rage)
	SOL.add_ui_child(rage, -1)


func _exit_tree() -> void:
	pass


func _on_popo_1_interact_on_interact() -> void:
	var newbounts := false
	for b in tracked_bounties:
		if is_bounty_fulfilled(b):
			if not DAT.get_data("fulfilled_bounty_%s" % b, false):
				if not newbounts:
					SOL.dialogue("bounty_complete_pre")
					newbounts = true
				var complete_dial := ("bounty_complete_%s" % b) as String
				var reward_path := (
					"res://resources/rewards/bounty/res_%s.tres" % b) as String
				var reward : BattleRewards = null
				if ResourceLoader.exists(reward_path):
					reward = load(reward_path)
				if complete_dial in SOL.dialogue_box.dialogues_dict:
					SOL.dialogue(complete_dial)
				if reward: reward.grant()
				DAT.set_data("fulfilled_bounty_%s" % b, true)
				DAT.incri("police_standing", 1)
	SOL.dialogue(get_greeting())
	SOL.dialogue("police_main")
	if DAT.get_data("police_standing", 0) < 1:
		DAT.set_data("police_standing", 1)
		DAT.set_data("police_sitting", 0)


func _bounty_interacted() -> void:
	get_bounty_info()
	SOL.dialogue("bounty_board")


func load_bounties() -> void:
	bounty["thugs"] = 0
	bounty["stray_animals"] = 0
	bounty["broken_fishermen"] = 0
	bounty["sun_spirit"] = 0
	bounty["president"] = 0
	bounty["vampire"] = 0
	bounty["circus"] = 0
	for p in DAT.get_data("party", ["greg"]):
		var charc := DAT.get_character(p) as Character
		for i in thugs:
			bounty["thugs"] += cd(charc, i)
		for i in broken:
			bounty["broken_fishermen"] += cd(charc, i)
		for i in animals:
			bounty["stray_animals"] += cd(charc, i)
		bounty["sun_spirit"] += cd(charc, "sun_spirit")
		bounty["president"] += cd(charc, "dish")
		bounty["circus"] += cd(charc, "ringleader")


func cd(w: Character, c: StringName) -> int:
	return w.get_defeated_character(c)


func get_bounty_info() -> void:
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


func get_greeting() -> String:
	var standing := DAT.get_data("police_standing", 0) as int
	if Math.inrange(standing, 0, 2):
		return "police_greeting"
	elif Math.inrange(standing, 3, 5):
		return "police_greeting_happy"
	return "police_greeting"


func is_bounty_fulfilled(nomen: String) -> bool:
	return bounty[nomen] >= (BOUNTY_CATCHES[nomen] if nomen in BOUNTY_CATCHES else 1)


func fulfill_bounty(nomen: String) -> void:
	if nomen == "all":
		for i in tracked_bounties:
			fulfill_bounty(i)
		return
	bounty[nomen] = (BOUNTY_CATCHES[nomen] if nomen in BOUNTY_CATCHES else 1)


func setup_cells() -> void:
	if not DAT.get_data("trash_guy_inspected", false):
		cells["trash_guy"].queue_free()
	
	for i in tracked_bounties:
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
			"enabled" if DAT.get_data("thugs_enabled", false) else "disabled")))
	if is_bounty_fulfilled("sun_spirit"):
		$Cells/SunSpirit/SunSpiritInspect.inspected.connect(art_sun_spirit_rage)


# this is source code poetry
func art_sun_spirit_rage()->void:{false:func():rage.show();var twe:=\
create_tween();rage.get_child(1).modulate.a=0.0;twe.tween_property(rage.\
get_child(1),"modulate:a",1.0,0.4);SND.play_song("");SND.play_sound(preload\
("res://sounds/spirit/solar/snd_flare.ogg"),{"pitch":0.5,"volume":-10});SOL.\
dialogue("insp_sun_spirit_rage_1");DAT.set_data("suspirit_inspected",true);SOL.\
dialogue_closed.connect(func():SOL.dialogue("insp_sun_spirit_rage_2");rage.\
get_child(1).queue_free();SOL.dialogue_closed.connect(func():var tw:=\
create_tween();tw.tween_property(rage,"modulate:a",0.0,2.0);SND.play_song(
"police"),CONNECT_ONE_SHOT),CONNECT_ONE_SHOT)}.get(DAT.get_data(
"suspirit_inspected",false),func():SOL.dialogue("insp_sun_spirit")).call()
