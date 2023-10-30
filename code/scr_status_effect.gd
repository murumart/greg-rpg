class_name StatusEffect extends Resource

# quick thing to store status effect applying in BattlePayload



const ICONS := {
	"poison": Rect2(0, 0, 6, 6),
	"coughing": Rect2(6, 0, 6, 6),
	"coughing_immunity": Rect2(24, 0, 6, 6),
	"fire": Rect2(12, 0, 6, 6),
	"confusion": Rect2(18, 0, 6, 6),
	"attack": Rect2(0, 6, 6, 6),
	"defense": Rect2(6, 6, 6, 6),
	"speed": Rect2(12, 6, 6, 6),
	"magnet": Rect2(18, 6, 6, 6),
	"regen": Rect2(0, 12, 6, 6),
	"shield": Rect2(6, 12, 6, 6),
	"sleepy": Rect2(12, 12, 6, 6)
}

@export var name := ""
@export var strength := 1.0
@export var duration := 1


func _init() -> void:
	pass


func set_effect_name(x: String) -> StatusEffect:
	name = x; return self


func set_strength(x: float) -> StatusEffect:
	strength = x; return self
	

func set_duration(x: int) -> StatusEffect:
	duration = x; return self
