extends BattleEnemy


func _ready() -> void:
	super()
	SOL.dialogue("vampire_battle_start")


func act() -> void:
	super()


func hurt(amt: float, _g: int) -> void:
	super(amt, _g)


func _item_salt_used_on() -> void:
	SOL.dialogue("test")
