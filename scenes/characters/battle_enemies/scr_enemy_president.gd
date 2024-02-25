extends BattleEnemy


func _ready() -> void:
	super()
	var tw := create_tween()
	tw.tween_property(self, "global_position:y", 190.0, 7.0).from(189.0)
	tw.tween_property(self, "global_position:y", 1.0, 14)
	tw.parallel().tween_property(self, "modulate", Color.WHITE, 30
			).from(Color.BLACK)
