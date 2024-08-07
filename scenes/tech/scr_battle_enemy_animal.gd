class_name EnemyAnimal extends BattleEnemy

signal dance_battle_requested(ba: EnemyAnimal, target: BattleActor)

var soul := 0.0


func _ready() -> void:
	super._ready()
	soul = rng.randf() * 25


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
		var test_for_tasty := Math.determ_shuffle(reference_to_actor_array.duplicate(), rng)
		for actor: BattleActor in test_for_tasty:
			if actor.has_status_effect(&"appetising") and actor != self:
				return actor
	return super(who)


func hurt(amount: float, gnd: int) -> void:
	super(amount, gnd)
	if state != States.DEAD:
		soul += remap(amount, 1, 50, 5, 10)
		return
	# dead
	DAT.incri("killed_" + character.name_in_file, 1)


func get_xp() -> int:
	var xp := super()
	return roundi(xp + xp * 0.0025 * soul)
