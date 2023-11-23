extends OverworldCharacter

const TWERP_SYNONYMS := ["twerp", "twerp", "twerp", "nitwit", "nincompoop", "sucker", "moron", "nullity", "insect"]
const ENGAGE_SYNONYMS := ["engage", "engage", "engage", "feature", "be involved", "be engrossed", "lose",]
const TUSSLE_SYNONYMS := ["tussle", "tussle", "tussle", "struggle", "scuffle", "brawl", "scramble"]

const C := "chimney"
const W := "well"
const SC := "shopping_cart"
const SF := "stabbing_fella"
const KS := "kor_sten"
const A := "abiss"
const M := "moron"

static var thugs_battled_changed := false

@export var chimney_probability : Curve
@export var well_probability : Curve
@export var shopping_cart_probability : Curve
@export var stabbing_fella_probability : Curve
@export var kor_sten_probability : Curve
@export var abiss_probability : Curve
@export var moron_probability : Curve

@onready var probabilities := {
	C: chimney_probability,
	W: well_probability,
	SC: shopping_cart_probability,
	SF: stabbing_fella_probability,
	KS: kor_sten_probability,
	A: abiss_probability,
	M: moron_probability,
}


func _ready() -> void:
	super._ready()
	battle_info = BattleInfo.new()
	battle_info.set_enemies(gen_enemies()).set_music("daylightthief").set_background("town")
	battle_info.set_rewards(preload("res://resources/rewards/res_thug_reward.tres")).set_start_text("various thug(s) accost you.")


func chase(body) -> void:
	super.chase(body)
	SOL.dialogue_box.dial_concat("thug_catch_1", 0, [TWERP_SYNONYMS.pick_random(), ENGAGE_SYNONYMS.pick_random(), TUSSLE_SYNONYMS.pick_random()])


func interacted() -> void:
	super()
	if not thugs_battled_changed:
		DAT.incri("thugs_battled", battle_info.enemies.size())
		thugs_battled_changed = true
		LTS.scene_changed.connect(func(): thugs_battled_changed = false,
			CONNECT_ONE_SHOT)


func gen_enemies() -> Array[String]:
	var enemies : Array[String] = []
	var level := remap(DAT.get_character("greg").level, 1, 99, 0.001, 1.0)
	if not DAT.get_data("hunks_enabled", false):
		for i in ceili(level / 10.0) + 1:
			for k in probabilities.keys():
				var curve := probabilities[k] as Curve
				if curve.sample(level) >= randf():
					enemies.append(k)
	else:
		for i in level * 5:
			enemies.append("hunk")
	enemies.shuffle()
	if enemies.size() < 1: enemies.append(M)
	if M in enemies:
		enemies.push_front(enemies.pop_at(enemies.find(M)))
		battle_info.set_death_reason("moron")
	if enemies.size() > 4:
		enemies.resize(4)
	return enemies

