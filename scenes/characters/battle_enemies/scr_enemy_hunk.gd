extends BattleEnemy


func _ready() -> void:
	super._ready()
	if randf() <= 0.5:
		$Sprite2D.texture = preload("res://sprites/characters/battle/thugs/spr_thug_buff_n.png")
