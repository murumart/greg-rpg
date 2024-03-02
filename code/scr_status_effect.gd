class_name StatusEffect extends Resource

# quick thing to store status effect applying in BattlePayload

const GENDER_ROLES := {
	Genders.BRAIN: [&"sleepy"],
	Genders.ELECTRIC: [&"electric", &"speed", &"magnet"],
	Genders.FLAMING: [&"fire", &"attack", &"sopping_immunity"],
	Genders.GHOST: [&"shield"],
	Genders.SOPPING: [&"sopping", &"defense", &"coughing"],
	Genders.VAST: [&"confusion"],
}

const USE_ROLES := {
	Spirit.Uses.HEALING: [&"regen"],
	Spirit.Uses.HURTING: [&"poison", &"coughing", &"fire"],
	Spirit.Uses.BUFFING: [&"attack", &"defense", &"speed",
		&"inspiration", &"shield", &"electric"],
	Spirit.Uses.DEBUFFING: [&"coughing", &"sopping", &"sleepy",
		&"confusion"],
}

const COSTS := {
	&"poison": 5,
	&"coughing": 3,
	&"fire": 6,
	&"confusion": 17,
	&"attack": 5,
	&"defense": 5,
	&"speed": 7,
	&"magnet": 12,
	&"inspiration": 55,
	&"regen": 6,
	&"shield": 8,
	&"sleepy": 8,
	&"sopping": 6,
	&"appetising": 16,
	&"little": 8,
	&"electric": 7,
}

@export var name := &""
@export var strength := 1.0
@export var duration := 1


func _init() -> void:
	pass


func set_effect_name(x: StringName) -> StatusEffect:
	name = x; return self


func set_strength(x: float) -> StatusEffect:
	strength = x; return self


func set_duration(x: int) -> StatusEffect:
	duration = x; return self
