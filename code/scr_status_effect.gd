class_name StatusEffect extends Resource

# quick thing to store status effect applying in BattlePayload



const ICONS := {
	&"poison": Rect2(0, 0, 6, 6),
	&"coughing": Rect2(6, 0, 6, 6),
	&"coughing_immunity": Rect2(24, 0, 6, 6),
	&"fire": Rect2(12, 0, 6, 6),
	&"confusion": Rect2(18, 0, 6, 6),
	&"attack": Rect2(0, 6, 6, 6),
	&"defense": Rect2(6, 6, 6, 6),
	&"speed": Rect2(12, 6, 6, 6),
	&"magnet": Rect2(18, 6, 6, 6),
	&"inspiration": Rect2(24, 6, 6, 6),
	&"regen": Rect2(0, 12, 6, 6),
	&"shield": Rect2(6, 12, 6, 6),
	&"sleepy": Rect2(12, 12, 6, 6),
	&"sopping": Rect2(18, 12, 6, 6)
}

const DESCRIPTIONS := {
	&"default": "i'm afraid i don't have the expertise for this one.",
	&"default_immunity": "you are immune to %s.",
	&"poison": "you will lose a bit of life every time you act.",
	&"poison_immunity": "you are immune to poison.",
	&"coughing": "you will painfully cough every once in a while.",
	&"coughing_immunity": "you are immune to coughing.",
	&"fire": "you're on fire, taking damage every time you act.",
	&"confusion": "you're not quite sure whom you're going to hit...",
	&"attack": "your natural attacks grow more powerful.",
	&"defense": "you withstand natural blows better.",
	&"speed": "you are more nimble, being able to act more often.",
	&"magnet": "finishing a fight with this will give you more exp. and silver.",
	&"inspiration": "you regain some [color=#00ffff]spirit power[/color] every time you act.",
	&"regen": "you regain some life after every action.",
	&"shield": "a good chunk of damage will be blocked.",
	&"sleepy": "you cannot act. any damage will hurt more but also wake you.",
	&"sopping": "you're wet and pathetic and receive extra damage for it.",
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
