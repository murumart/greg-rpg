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


func _ready() -> void:
	super._ready()
	battle_info = BattleInfo.new()
	battle_info.set_enemies(gen_enemies()).set_music("daylightthief").set_background("town")
	battle_info.set_rewards(preload("res://resources/rewards/res_thug_reward.tres")).set_start_text("various thug(s) accost you.")


func chase(body) -> void:
	super.chase(body)
	SOL.dialogue_box.dial_concat("thug_catch_1", 0, [TWERP_SYNONYMS.pick_random(), ENGAGE_SYNONYMS.pick_random(), TUSSLE_SYNONYMS.pick_random()])


func gen_enemies() -> Array[String]:
	var enemies : Array[String] = []
	var level := DAT.get_character("greg").level
	if level < 3:
		enemies.append(C)
	elif Math.inrange(level, 3, 5):
		enemies.append(C)
		if randf() <= 0.33: enemies.append(W)
		if randf() <= 0.25: enemies.append(SC)
	elif Math.inrange(level, 6, 8):
		enemies.append(C)
		if randf() <= 0.25: enemies.append(C)
		if randf() <= 0.33: enemies.append(W)
		if randf() <= 0.1: enemies.append(W)
		if randf() <= 0.1: enemies.append(SF)
		if randf() <= 0.2: enemies.append(SC)
	elif Math.inrange(level, 8, 12):
		enemies.append(C)
		if randf() <= 0.5: enemies.append(C)
		if randf() <= 0.5: enemies.append(W)
		if randf() <= 0.25: enemies.append(A)
		if randf() <= 0.15: enemies.append(W)
		if randf() <= 0.05: enemies.append(SF)
		if randf() <= 0.05: enemies.append(SC)
		if randf() <= 0.05: enemies.append(KS)
	elif Math.inrange(level, 12, 20):
		enemies.append(C)
		enemies.append(SF)
		enemies.append(W)
		enemies.append(SC)
		if randf() <= 0.5: enemies.append(C)
		if randf() <= 0.5: enemies.append(W)
		if randf() <= 0.5: enemies.append(KS)
		if randf() <= 0.25: enemies.append(A)
		if randf() <= 0.15: enemies.append(W)
		if randf() <= 0.15: enemies.append(SF)
		if randf() <= 0.25: enemies.append(SC)
	elif Math.inrange(level, 20, 25):
		enemies.append(C)
		enemies.append(SF)
		enemies.append(W)
		enemies.append(SC)
		if randf() <= 0.75: enemies.append(W)
		if randf() <= 0.75: enemies.append(SF)
		if randf() <= 0.75: enemies.append(KS)
		if randf() <= 0.75: enemies.append(A)
		if randf() <= 0.05: enemies.append(M)
	else:
		enemies.append(KS)
		enemies.append(SF)
		enemies.append(A)
		enemies.append(SC)
		if randf() <= 0.1: enemies.append(M)
	enemies.shuffle()
	if M in enemies:
		enemies.push_front(enemies.pop_at(enemies.find(M)))
		battle_info.set_death_reason("moron")
	if enemies.size() > 4:
		enemies.resize(4)
	return enemies

