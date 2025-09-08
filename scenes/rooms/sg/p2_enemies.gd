extends Node2D

static var chars_genned := false

@export var default_battle: BattleInfo

var rng: RandomNumberGenerator


func _ready() -> void:
	_generate_characters()
	for c: OverworldCharacter in get_children():
		c.battle_info = default_battle.duplicate()
		c.battle_info.enemies.append("gen_char_" + str(randi_range(0, 9)))
		if randf() < 0.4:
			c.battle_info.enemies.append("gen_char_" + str(randi_range(0, 9)))
		if randf() < 0.1:
			c.battle_info.enemies.append("gen_char_" + str(randi_range(0, 9)))


func _generate_characters() -> void:
	if chars_genned: return
	rng = RandomNumberGenerator.new()
	rng.seed = int(DAT.get_data("nr", 0.0) * 1000)
	var aval_spirits := ["alpha_radio", "airspace_violation", "flare", "ghostpunches", "dreaming_in_green", "fish_attack",
	"grandma_electric", "grandma_debuff", "grassy_vengeance", "hook_attack", "radiation_attack", "sideeye", "smallshield"]
	var aval_weapons := ["animal_bite", "animal_bite_poisonous", "fish", "brick", "dish_attack", "forest_fire_attack"]
	for i in 10:
		var fn := "gen_char_" + str(i)
		var char := Character.new()
		char.name = _get_name()
		char.name_in_file = fn
		char.max_health = roundf(rng.randfn(80, 20))
		char.health = char.max_health
		char.max_magic = maxf(roundf(rng.randfn(100, 200)), 1.0)
		char.magic = char.max_magic
		char.level = roundi(rng.randfn(85, 6))
		char.attack = roundi(rng.randfn(85, 6))
		char.defense = roundi(rng.randfn(85, 6))
		char.speed = roundi(rng.randfn(85, 6))
		char.spirits.append(aval_spirits.pop_at(rng.randi_range(0, aval_spirits.size() - 1)))
		if rng.randf() < 0.33 and not aval_weapons.is_empty():
			char.weapon = aval_weapons.pop_at(rng.randi_range(0, aval_weapons.size() - 1))

		ResMan.characters[fn] = char

func _get_name() -> String:
	const beg: Array[String] = [
		"a", "b", "en", "de", "do", "go", "x",
	]
	const syl: Array[String] = ["be", "by", "gy", "on", "ol", "pop", "po", "yu", "a"]
	const adject: Array[String] = ["forgotten", "forlorn", "hollow", "empty", "vengeful", "purple",
	"reemergent", "returning", "unfinished",]
	const word: Array[String] = ["green", "object", "entity", "being", "routine", "lifeform", "system",
	"concept", "machine", "string", "word", "data"]

	var n := ""
	if rng.randf() < 0.33:
		n = Math.determ_pick_random(beg, rng)
		for i in randi_range(1, 4):
			n +=  Math.determ_pick_random(syl, rng)
	else:
		n =  Math.determ_pick_random(word, rng)

	if rng.randf() < 0.1:
		var a: String = Math.determ_pick_random(beg, rng)
		for i in randi_range(1, 4):
			a +=  Math.determ_pick_random(syl, rng)
		n = a + " " + n
	else:
		n = Math.determ_pick_random(adject, rng) + " " + n

	if rng.randf() < 0.5:
		if rng.randf() < 0.5:
			var vowel := ["a", "e", "i", "o", "u"]
			if n[0] in vowel:
				n = "an " + n
			else:
				n = "a " + n
		else:
			n = "the " + n

	return n
