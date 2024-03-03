class_name ManaGate extends Resource

const Uses := Spirit.Uses
const USES_ORDER := [Uses.HEALING, Uses.HURTING, Uses.BUFFING, Uses.DEBUFFING]
const USES_WEIGHTS := [3, 9, 4, 7]

const GENDER_ORDER := [Genders.BRAIN, Genders.ELECTRIC, Genders.FLAMING,
	Genders.GHOST, Genders.SOPPING, Genders.VAST, Genders.NONE]
const GENDER_WEIGHTS := [3, 4, 5, 4, 5, 1, 1]

var _random: RandomNumberGenerator

@export var use: Spirit.Uses = Uses.NONE
@export_enum(
	"None", "Electric",
	"Sopping", "Burning",
	"Ghost", "Brain", "Vast", "Random"
	) var gender: int = 7


func _init(rng: RandomNumberGenerator, options := {}) -> void:
	_random = rng
	use = options.get("use",
		Math.weighted_random(USES_ORDER, USES_WEIGHTS)
		if use == Uses.NONE else use) as Uses
	gender = options.get("gender",
		Math.weighted_random(GENDER_ORDER, GENDER_WEIGHTS)
		if gender == Genders.NONE else gender) as int


func get_spirit(level: int) -> Spirit:
	var s := Spirit.new() as Spirit
	s.name = MGRandomName.gen_name(_random)
	s.use = use
	var plgen := MGPayload.new(_random, level, s.use, gender)
	s.payload = plgen.pload()
	s.cost = plgen.mcost
	s.description += "lvl " + str(level)
	if s.cost == level:
		return get_spirit(level + 5)
	return s


class MGPayload:

	static var STATEFF_ORDER := ResMan.status_effect_types.keys()
	const HIGH_VARIANCE_EFFECTS := [&"attack", &"defense", &"speed"]
	const QUARTER_VARIANCE_EFFECTS := [
		&"regen", &"inspiration", &"poison", &"coughing", &"sopping", &"electric"]
	const RESTRICTED_EFFECTS := [
		&"confusion", &"shield", &"appetising", &"little", &"sleepy"]
	const STATEFF_WEIGHTS := [10, 6, 2, 8]

	var rng: RandomNumberGenerator
	var lvl: int
	var use: Uses
	var gender: int
	var mcost := 0


	func _init(
				_rng: RandomNumberGenerator,
				_lvl: int,
				_use: Uses,
				_gender: int
			) -> void:
		rng = _rng
		lvl = _lvl
		use = _use
		gender = _gender
		if gender == Genders.RANDOM:
			gender = Math.weighted_random(GENDER_ORDER, GENDER_WEIGHTS)


	func pload() -> BattlePayload:
		var pl := BattlePayload.new()
		var much := float(lvl)
		var repears := mini(rng.randfn(2, 1), 1) + int(lvl / 70)
		if rng.randf() < 0.04:
			repears += rng.randi_range(1, 6)
		pl.type = BattlePayload.Types.SPIRIT
		var tries := 0
		while true:
			if rng.randf() < 0.5:
				print("choosing status effect")
				var se := stateff(much)
				if se.name in pl.effects.map(func(a): return a.name):
					continue
				pl.effects.append(se)
				tries += 1
			else:
				print("choosing resource effect")
				if use == Uses.HEALING:
					var t := rng.randf()
					if t <= 0.66 and much > 9:
						pl.health = rng.randi_range(50, 91)
					elif t <= 0.88:
						pl.health_percent = rng.randi_range(20, 48)
					elif much > 26:
						pl.max_magic_percent = rng.randi_range(10, 48)
					else:
						pl.health = rng.randi_range(1, 199)
					tries += 1
				elif use == Uses.HURTING:
					var t := rng.randf()
					if t <= 0.66 and much > 9:
						pl.health = rng.randi_range(-10, -50)
					elif t <= 0.88:
						pl.health_percent = rng.randi_range(-10, -20)
					elif much > 26:
						pl.max_magic_percent = rng.randi_range(-10, -20)
					else:
						pl.health = rng.randi_range(1, 199)
					tries += 1
			if much < -100 or much > 300:
				pl.effects.clear()
				much = 0
			much -= plcost(pl)
			if tries >= repears:
				break
		pl.gender = gender
		mcost = lvl
		mcost += plcost(pl)
		return pl


	func stateff(much: float) -> StatusEffect:
		var se := StatusEffect.new()
		se.duration = rng.randi_range(2, 4)
		var rand_start := 1.0
		if rng.randf() < 0.1:
			rand_start = randf_range(-10, much / 2)

		se.name = _eff_name()
		if rng.randf() < 0.2:
			se.duration += rng.randf_range(-10, 10)
		elif rng.randf() < 0.2:
			se.strength += rng.randf_range(-6, 12)

		var rand_end := 5.0
		if se.name in HIGH_VARIANCE_EFFECTS:
			rand_end = much
			rand_start = maxf(rand_start, much * 0.33)
		elif se.name in QUARTER_VARIANCE_EFFECTS:
			rand_end = much * 0.25
		elif se.name in RESTRICTED_EFFECTS or se.name.ends_with("_immunity"):
			rand_end = 1
			rand_start = 1
		else:
			rand_end = maxf(rand_end, rand_start + 5.0)
		se.strength = randf_range(rand_start, rand_end)

		for _n in 5:
			var cost := secost(se)
			if cost >= much:
				if rng.randf() <= 0.66:
					se.duration = maxf(se.duration + rng.randi_range(-3, 1), 1)
				else:
					se.strength = maxf(se.strength + rng.randf_range(-3, 1), 1)

		if se.strength > 0:
			se.strength = ceilf(se.strength)
		else:
			se.strength = floorf(se.strength)
		if se.duration == 0:
			se.set_strength(0)
		return se


	func _eff_name() -> StringName:
		# choose name
		var name := &""
		var union := Math.array_union(
				ResMan.gender__effects.get(gender, STATEFF_ORDER),
				ResMan.use__effects.get(use, STATEFF_ORDER)
		)
		if rng.randf() <= 0.96:
			if union.is_empty():
				union = Math.determ_pick_random(
					[
						ResMan.gender__effects.get(gender, STATEFF_ORDER),
						ResMan.use__effects.get(use, STATEFF_ORDER)
					], rng
				)
				if rng.randf() < 0.75:
					gender = Genders.NONE
			name = Math.determ_pick_random(union, rng) as StringName
		else:
			if union.is_empty():
				union = Math.determ_pick_random(
					[
						ResMan.gender__effects.get(gender, STATEFF_ORDER),
						ResMan.use__effects.get(use, STATEFF_ORDER)
					], rng
				)
			name = Math.determ_pick_random(STATEFF_ORDER, rng)
		if rng.randf() < 0.95 and name.ends_with("_immunity"):
			return _eff_name()
		return name


	static func secost(eff: StatusEffect) -> float:
		var cost := 0.0
		var semult := 0.5
		if eff.name in HIGH_VARIANCE_EFFECTS:
			semult = 0.25
		cost += StatusEffect.COSTS.get(eff.name,
				8) * absf(eff.duration) * semult * absf(eff.strength) as float
		if eff.name in RESTRICTED_EFFECTS and eff.strength != 1:
			cost += absf(eff.strength * 10)
		return cost


	static func plcost(pl: BattlePayload) -> float:
		var sc := 0.0
		for x in pl.effects:
			sc += secost(x)
		if pl.health > 0:
			sc += (pl.health * 0.6)
		elif pl.health < 0:
			sc -= (pl.health * 1.2)
		if pl.health_percent > 0:
			sc += (pl.health_percent)
		elif pl.health_percent < 0:
			sc -= (pl.health_percent * 2)
		if pl.max_health_percent > 0:
			sc += (pl.max_health_percent * 1.5)
		elif pl.max_health_percent > 0:
			sc -= (pl.max_health_percent * 4)
		print(sc)
		return sc


class MGRandomName:

	const NAME_LEN_MIN = 6
	const NAME_LEN_MAX = 9
	const SYLLABLES: Array[String] = ["ba", "be", "bi", "bo", "bu"]


	static func gen_name(rng: RandomNumberGenerator) -> String:
		var name := ""
		var lenght := rng.randi_range(NAME_LEN_MIN, NAME_LEN_MAX)
		while name.length() < lenght:
			name += Math.determ_pick_random(SYLLABLES, rng)
		return name
