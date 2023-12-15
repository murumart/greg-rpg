class_name EnemyAnimal extends BattleEnemy

signal dance_battle_requested(ba: EnemyAnimal, target: BattleActor)

var soul := 0.0


func _ready() -> void:
	super._ready()
	soul = randf() * 25


func act() -> void:
	super.act()
	soul += 8.5


func attack(target: BattleActor) -> void:
	if soul >= 100:
		dance_battle_requested.emit(self, target)
		soul = 0.0
		return
	super(target)


func pick_target(who: int = 0) -> BattleActor:
	if who != SELF:
		var test_for_tasty := reference_to_actor_array.duplicate()
		test_for_tasty.shuffle()
		for actor: BattleActor in test_for_tasty:
			if actor.has_status_effect(&"appetising"):
				return actor
	return super(who)


func hurt(amount: float, gnd: int) -> void:
	super(amount, gnd)
	if state != States.DEAD:
		soul += remap(amount, 1, 50, 5, 10)
