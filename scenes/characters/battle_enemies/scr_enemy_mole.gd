extends EnemyAnimal

var hiding := false: set = set_hiding
const IMM_LIST : Array[String] = ["poison", "coughing"]
const IMM_LIST_EMPTY : Array[String] = []
var hiding_time := 0


func set_hiding(to: bool) -> void:
	hiding = to
	$Sprite2D.texture = preload("res://sprites/characters/battle/animals/spr_mole_roll.png") if to else preload("res://sprites/characters/battle/animals/spr_mole.png")
	xp_multiplier = 3.0 if to else 1.0
	effect_immunities = IMM_LIST if to else IMM_LIST_EMPTY
	character.defense = 95 if to else 14
	hiding_time = 0


func ai_action() -> void:
	super.ai_action()
	if hiding:
		hiding_time += 1
	if hiding_time > 4:
		hiding = false


func flee() -> void:
	if not hiding:
		super.flee()
	else: turn_finished()


func hurt(amt: float) -> void:
	super.hurt(amt)
	if randf() <= 0.25 and not hiding:
		hiding = true
		emit_message("%s rolls up!" % actor_name)
		introduce_status_effect("regen", 1.0, 1)


func attack(who: BattleActor) -> void:
	if not hiding:
		super.attack(who)
	else:
		if randf() <= 0.25:
			hiding = false
			emit_message("%s unrolls!" % actor_name)
		turn_finished()

