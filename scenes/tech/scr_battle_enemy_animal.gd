class_name EnemyAnimal extends BattleEnemy

signal dance_battle_requested(ba: EnemyAnimal)

var soul := 0.0


func _ready() -> void:
	super._ready()
	soul = randf() * 25


func act() -> void:
	if soul >= 100:
		dance_battle_requested.emit(self)
		soul = 0.0
		return
	super.act()
	soul += 8.5


func hurt(amount: float, gnd: int) -> void:
	super(amount, gnd)
	if state != States.DEAD:
		soul += remap(amount, 1, 50, 5, 10)
