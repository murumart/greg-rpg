extends BattleEnemy


func _ready() -> void:
	super()
	if LTS.get_current_scene().name == "Battle":
		var bg = LTS.get_current_scene().background_container.get_child(0)
		if bg.skip_intro:
			return
	var tw := create_tween()
	tw.tween_property(self, "global_position:y", 190.0, 7.0).from(189.0)
	tw.tween_property(self, "global_position:y", 1.0, 14)
	tw.parallel().tween_property(self, "modulate", Color.WHITE, 30
			).from(Color.BLACK)
