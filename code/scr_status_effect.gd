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
}

@export var name := ""
@export var strength := 1.0
@export var duration := 1
