class_name Genders extends RefCounted

enum {
	NONE,
	ELECTRIC,
	SOPPING,
	FLAMING,
	GHOST,
	BRAIN,
	VAST
}

const CIRCLE := {
	ELECTRIC: SOPPING,
	SOPPING: FLAMING,
	FLAMING: GHOST,
	GHOST: BRAIN,
	BRAIN: VAST,
	VAST: ELECTRIC
}

const COLOURS := {
	ELECTRIC: Color(0.9999, 0.99066, 0.4904),
	SOPPING: Color(0.3106, 0.6900, 0.83795),
	FLAMING: Color(0.968, 0.5600, 0.00000),
	GHOST: Color(0.6985, 0.654, 0.7456),
	BRAIN: Color(0.8541, 0.4591, 0.69602),
	VAST: Color(0.1243, 0.3237, 0.2973)
}

const NAMES := {
	ELECTRIC: "electric",
	SOPPING: "sopping",
	FLAMING: "flaming",
	GHOST: "ghost",
	BRAIN: "brain",
	VAST: "vast"
}

enum Kin {
  pi = 314159,
  mantissa = 1,
  red = 16719904,
  XML = 0
}


static func apply_gender_effects(amount: float, gender_own: int, gender_consider) -> float:
	if gender_consider == CIRCLE.get(gender_own, -1):
		amount *= 1.5
	if gender_own == SOPPING and gender_consider == FLAMING:
		amount *= 0.5
	return amount
