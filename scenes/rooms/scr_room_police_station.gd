extends Room

@onready var popo1 := $Npcs/Popo1 as OverworldCharacter

var bounty := {}
var tracked_bounties := ["thugs", "bike_ghost", "stray_animals", "broken_fishermen", "sun_spirit"]
var thugs := ["chimney", "well", "shopping_cart", "kor_sten", "abiss", "moron", "stabbing_fella"]
var broken := ["broken_fisherman", "not_fish", "sopping"]
var animals := ["mole", "rainbird", "stray_pet", "wild_lizard"]
const BOUNTY_CATCHES := {
	"thugs": 40,
	"bike_ghost": 1,
	"stray_animals": 40,
	"broken_fishermen": 40,
	"sun_spirit": 1,
}



func _ready() -> void:
	super._ready()
	load_bounties()
	
	if not DAT.get_data("trash_guy_inspected", false):
		$Cells/Cell/TrashGuy.queue_free()
		$Cells/Cell/TrashInspect.queue_free()


func _on_popo_1_interact_on_interact() -> void:
	SOL.dialogue("police_greeting")
	if DAT.get_data("police_standing", 0) < 1:
		DAT.set_data("police_standing", 1)
		DAT.set_data("police_sitting", 0)


func _bounty_interacted() -> void:
	get_bounty_info()
	SOL.dialogue("bounty_board")


func load_bounties() -> void:
	bounty["thugs"] = 0
	bounty["bike_ghost"] = 0
	bounty["stray_animals"] = 0
	bounty["broken_fishermen"] = 0
	bounty["sun_spirit"] = 0
	for p in DAT.get_data("party", ["greg"]):
		var charc := DAT.get_character(p) as Character
		for i in thugs:
			bounty["thugs"] += cd(charc, i)
		bounty["bike_ghost"] += cd(charc, "bike_ghost")
		for i in broken:
			bounty["broken_fishermen"] += cd(charc, i)
		for i in animals:
			bounty["stray_animals"] += cd(charc, i)
		bounty["sun_spirit"] += cd(charc, "sun_spirit")


func cd(w: Character, c: StringName) -> int:
	return w.get_defeated_character(c)


func get_bounty_info() -> void:
	SOL.dialogue_box.dial_concat("bounty_board", 3, [
		bounty.get("thugs", 0),
		BOUNTY_CATCHES["thugs"]
	])
	SOL.dialogue_box.dial_concat("bounty_board", 6, [
		" not " if not bounty.get("bike_ghost", 0) else " "
	])
	SOL.dialogue_box.dial_concat("bounty_board", 9, [
		bounty.get("stray_animals", 0),
		BOUNTY_CATCHES["stray_animals"]
	])
	SOL.dialogue_box.dial_concat("bounty_board", 12, [
		bounty.get("broken_fishermen", 0),
		BOUNTY_CATCHES["broken_fishermen"]
	])
	SOL.dialogue_box.dial_concat("bounty_board", 15, [
		" not " if not bounty.get("sun_spirit", 0) else " "
	])

