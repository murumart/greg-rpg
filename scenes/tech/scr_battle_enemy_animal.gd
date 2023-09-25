class_name EnemyAnimal extends BattleEnemy

signal dance_battle_requested

var soul := 0.0


func _ready() -> void:
	super._ready()
	soul = randf() * 25


func act() -> void:
	if soul >= 100:
		dance_battle_requested.emit()
		return
	super.act()
	soul += 5


func hurt(amount: float) -> void:
	super.hurt(amount)
	if state != States.DEAD:
		soul += absf(amount)
