class_name CopyGregStatsComponent extends Node

enum CopyType {
	COPY_LEVEL, ## Copy initial character's level
	COPY_CHAR_ATTACK, ## Copy initial char's attack (stated in char file only)
	COPY_CHAR_DEFENSE, ## Copy initial char's defense (stated in char file only)
	COPY_CHAR_SPEED, ## Copy initial char's speed (stated in char file only)
	COPY_CHAR_HEALTH, ## Copy initial char's max health
	SET_HEALTH_BASED_ON_LVL, ## Set max health to a multiple of the initial char's level
	SET_ATTACK_BASED_ON_LVL, ## Set attack to a multiple of the initial char's level
	SET_DEFENSE_BASED_ON_LVL, ## Set defense to a multiple of the initial char's level
	SET_SPEED_BASED_ON_LVL, ## Set speed to a multiple of the initial char's level
}

## Keys specify what initial value to copy, values are multipliers on the initial value.
@export var copy_params: Dictionary[CopyType, float]
## Keys specify what initial value to copy, values are curves that output a value based on the initial value.
@export var copy_params_curve: Dictionary[CopyType, Curve]


func _ready() -> void:
	# character is ready before this is ready - hopefully
	get_parent().ready.connect(func():
		var character := (get_parent() as BattleActor).character
		var greg := ResMan.get_character("greg")
		copy_stats_d(greg, character, copy_params)
		copy_stats_c(greg, character, copy_params_curve)
	, CONNECT_ONE_SHOT)


static func copy_stats_d(from: Character, to: Character, params: Dictionary[CopyType, float]) -> void:
	for p in params:
		var mult := params[p]
		match p:
			CopyType.COPY_LEVEL: to.level = roundi(from.level * mult)
			CopyType.COPY_CHAR_ATTACK: to.attack = roundf(from.attack * mult)
			CopyType.COPY_CHAR_DEFENSE: to.defense = roundf(from.defense * mult)
			CopyType.COPY_CHAR_SPEED: to.speed = roundf(from.speed * mult)
			CopyType.COPY_CHAR_HEALTH:
				to.max_health = roundf(from.max_health * mult)
				to.health = to.max_health
			CopyType.SET_HEALTH_BASED_ON_LVL:
				to.max_health = roundf(from.level * mult)
			CopyType.SET_ATTACK_BASED_ON_LVL: to.attack = roundf(from.level * mult)
			CopyType.SET_DEFENSE_BASED_ON_LVL: to.defense = roundf(from.level * mult)
			CopyType.SET_SPEED_BASED_ON_LVL: to.speed = roundf(from.level * mult)
			_: assert(false, "Invalid copy value")


static func copy_stats_c(from: Character, to: Character, params: Dictionary[CopyType, Curve]) -> void:
	for p in params:
		var c := params[p]
		match p:
			CopyType.COPY_LEVEL: to.level = roundi(c.sample_baked(from.level))
			CopyType.COPY_CHAR_ATTACK: to.attack = roundf(c.sample_baked(from.attack))
			CopyType.COPY_CHAR_DEFENSE: to.defense = roundf(c.sample_baked(from.defense))
			CopyType.COPY_CHAR_SPEED: to.speed = roundf(c.sample_baked(from.speed))
			CopyType.COPY_CHAR_HEALTH:
				to.max_health = roundf(c.sample_baked(from.max_health))
				to.health = to.max_health
			CopyType.SET_HEALTH_BASED_ON_LVL:
				to.max_health = roundf(c.sample_baked(from.level))
				to.health = to.max_health
			CopyType.SET_ATTACK_BASED_ON_LVL: to.attack = roundf(c.sample_baked(from.level))
			CopyType.SET_DEFENSE_BASED_ON_LVL: to.defense = roundf(c.sample_baked(from.level))
			CopyType.SET_SPEED_BASED_ON_LVL: to.speed = roundf(c.sample_baked(from.level))
			_: assert(false, "Invalid copy value")


static func copy_stats_if_im_less(
			from_character: Character,
			to_character: Character,
			_multiplier := 1.0) -> void:
	to_character.attack = maxf(to_character.attack, roundf(from_character.attack * _multiplier))
	to_character.defense = maxf(to_character.defense, roundf(from_character.defense * _multiplier))
	to_character.speed = maxf(to_character.speed, roundf(from_character.speed * _multiplier))
	to_character.level = maxi(to_character.level, roundi(from_character.level * _multiplier))


static func copy_stats_from_advanced(
		from_character: Character,
		to_character: Character,
		_multiplier: float,
		which_ones: Array[StringName]) -> void:
	for stat in which_ones:
		var tget := roundf(from_character.get(stat) * _multiplier)
		to_character.set(stat, maxf(to_character.get(stat), tget))
