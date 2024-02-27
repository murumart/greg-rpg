class_name ManaGate extends Resource

const Uses := Spirit.Uses
const USES_ORDER := [Uses.HEALING, Uses.HURTING, Uses.BUFFING, Uses.DEBUFFING]
const USES_WEIGHTS := [3, 9, 4, 7]

const GENDER_ORDER := [Genders.BRAIN, Genders.ELECTRIC, Genders.FLAMING,
	Genders.GHOST, Genders.SOPPING, Genders.VAST]
const GENDER_WEIGHTS := [3, 4, 5, 4, 5, 1]

var _random: RandomNumberGenerator

@export var use: Spirit.Uses = Uses.NONE
@export_enum(
	"None", "Electric",
	"Sopping", "Burning",
	"Ghost", "Brain", "Vast"
	) var gender: int = 0


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
	s.payload = MGPayload.new(_random, level, s.use, gender).pload()
	return s


class MGPayload:
	
	static var STATEFF_ORDER := StatusEffect.ICONS.keys()
	const STATEFF_WEIGHTS := [10, 6, 2, 8]
	
	var rng: RandomNumberGenerator
	var lvl: int
	var use: Uses
	var gender: int
	
	
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
	
	
	func pload() -> BattlePayload:
		var pl := BattlePayload.new()
		var much := float(lvl)
		var repears := mini(rng.randfn(2, 1), 1)
		if rng.randf() < 0.04:
			repears += rng.randi_range(1, 6)
		pl.gender = gender
		pl.type = BattlePayload.Types.SPIRIT
		for i in repears:
			var _status_effect := Math.true_or_false(rng)
			if _status_effect:
				var se := stateff(much)
				pl.effects.append(se)
				much -= StatusEffect.COSTS.get(se.name,
					8) * se.duration * 0.5 * se.strength as float
			else:
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
					much -= pl.health * 0.1
					much -= pl.health_percent * 0.3
					much -= pl.max_health_percent * 0.6
		return pl
		
		
	func stateff(much: float) -> StatusEffect:
		var se := StatusEffect.new()
		se.duration = rng.randi_range(2, 4)
		se.strength = maxf(roundf(rng.randfn(1, 2)), 1.0)
		if rng.randf() <= 0.96:
			var union := Math.array_union(
					StatusEffect.GENDER_ROLES.get(gender, STATEFF_ORDER),
					StatusEffect.USE_ROLES.get(use, STATEFF_ORDER)
			)
			if union.is_empty():
				union = Math.determ_pick_random(
					[
						StatusEffect.GENDER_ROLES.get(gender, STATEFF_ORDER),
						StatusEffect.USE_ROLES.get(use, STATEFF_ORDER)
					], rng
				)
			se.name = Math.determ_pick_random(union, rng) as StringName

			for _n in 5:
				var cost := StatusEffect.COSTS.get(se.name,
					8) * se.duration * 0.5 * se.strength as float
				if cost >= much:
					if rng.randf() <= 0.33:
						se.name = Math.determ_pick_random(union, rng)
					elif rng.randf() <= 0.66:
						se.duration = maxf(se.duration + rng.randi_range(-2, 2), 1)
					else:
						se.strength = maxf(se.strength + rng.randf_range(-2, 2), 1)
		else:
			se.name = Math.determ_pick_random(STATEFF_ORDER, rng)
			if rng.randf() < 0.2:
				se.duration += rng.randf_range(-10, 10)
			elif rng.randf() < 0.2:
				se.strength += rng.randf_range(-6, 12)
		return se


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
