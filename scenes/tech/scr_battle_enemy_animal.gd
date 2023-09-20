class_name EnemyAnimal extends BattleEnemy


var soul := 0.0


func _ready() -> void:
	super._ready()
	soul = randf() * 25


func hurt(amount: float) -> void:
	super.hurt(amount)
	if state != States.DEAD:
		soul += absf(amount)
