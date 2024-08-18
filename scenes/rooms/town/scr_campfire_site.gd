extends Node2D
@onready var naturalist: OverworldCharacter = $Naturalist


func _ready() -> void:

	_naturalist_setup()


func _naturalist_setup() -> void:
	var exists_here: bool = (
			not (not DAT.get_data("vampire_fought", false)
					and Math.inrange(ResMan.get_character("greg").level, 40, 49))
			and LTS.gate_id != &"vampire_cutscene"
			and (PoliceStation.is_bounty_fulfilled_static("thugs")
					and not DAT.get_data("hunks_enabled", false))
			and PoliceStation.is_bounty_fulfilled_static("stray_animals"))
	if not exists_here:
		naturalist.queue_free()
		return
	var dbox := SOL.dialogue_box as DialogueBox
	var dnames := _generate_unique_bird_names()
	const BIRD_NAME_RANGE := Vector2i(62, 69)
	for i in range(BIRD_NAME_RANGE.x, BIRD_NAME_RANGE.y):
		var names := []
		for x in 3:
			names.append(dnames.pop_at(randi() % dnames.size()))
		dbox.dial_concat("naturalist_campsite", i, names)
	var names := []
	for x in 2:
		names.append(dnames.pop_at(randi() % dnames.size()))
	dbox.dial_concat("naturalist_campsite", BIRD_NAME_RANGE.y, names)


func _generate_unique_bird_names() -> Array[String]:
	var array: Array[String] = []
	var seed := DAT.get_data("nr", 0) as float
	var rng := RandomNumberGenerator.new()
	const SYLLABS := [
		"wa", "an", "ne", "tai", "ta", "pa", "cu", "lo",
		"em", "er", "al", "ori", "ole", "ea", "pe", "trel",
		"guan", "ho", "ner", "ma", "na", "kin", "oro", "pen",
		"dola", "pa", "ke", "pu", "co", "da", "cu", "fi", "fa",
		"my", "na", "pa", "ot", "rro", "ap", "ep", "yu", "ku",
		"al", "an", "ca", "wo", "wa", "we", "weh", "wu", "ro",
		"ll", "er", "a", "aa", "iu", "mori", "alla", "illa"
	]
	const FIRST_SYLLABS := [
		"wa", "an", "ne", "tai", "ta", "pa", "cu", "lo",
		"em", "er", "al", "ori", "ole", "ea", "pe", "trel",
		"guan", "ho", "ner", "ma", "na", "oro", "pen",
		"dola", "pa", "ke", "pu", "co", "da", "cu", "fi", "fa",
		"my", "na", "pa", "ap", "ep", "yu", "ku",
		"al", "an", "ca", "wo", "wa", "we", "weh", "wu", "ro",
		"er", "a", "e", "i", "o", "u"
	]
	const PREXES := [
		"the ", "green-", "blue-", "golden-", "red-throated ",
		"razor-winged ", "yellow-", "night ", "the blue ", "domestic ",
		"black-chested ", "boat-billed ", "band-tailed ", "banded ",
		"bare-faced ", "bald ", "common ", "the common ", "common green ",
		"chestnut-", "chestnut-bellied ", "dark-sided ", "dark-faced ",
		"geumian ", "eastern ", "eastern-", "sea ", "western ",
		"northern ", "northern-", "northeastern ", "water-",
		"edible-nest ", "ghostly ", "big-brained ", "flaming ",
		"sopping ", "vast ", "electric ", "the awesome ", "flavescent ",
		"iridescent ", "flat-billed ", "long-billed ", "flame-throated ",
		"flame-winged ", "flame-fronted ", "grey ", "great ", "great ",
		"the great ", "small ", "tiny ", "garden ", "grey-headed ",
		"grey-hooded ", "the ", "the ", "the "
	]
	const BIRD_NAME_AMOUNT := 64
	rng.seed = seed * 10000
	while array.size() < BIRD_NAME_AMOUNT:
		var basename: String = Math.determ_pick_random(FIRST_SYLLABS, rng)
		for i in randi_range(1, 4):
			basename += Math.determ_pick_random(SYLLABS, rng)
			if basename.length() > 7:
				break

		if rng.randf() < 0.75:
			basename = Math.determ_pick_random(PREXES, rng) + basename
		if rng.randf() < 0.05:
			basename = Math.determ_pick_random(PREXES, rng) + basename
		if basename in array:
			continue
		array.append(basename)
	return array


