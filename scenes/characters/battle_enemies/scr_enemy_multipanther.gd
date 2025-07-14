extends BattleEnemy

const WigglerType := preload("res://scenes/tech/scr_line_wiggler.gd")


func animate(animation: StringName, queue_idle := true) -> void:
	super(animation, queue_idle)
	if animation in ["attack", "use_spirit", "use_item"]:
		for child in $OutlineMe.get_children():
			child = child as WigglerType
			if not child:
				continue
			var wigrange: Vector2 = child.wiggle_range
			var tw := create_tween()
			tw.tween_property(child, "wiggle_range", Vector2(56, 56), 0.1)
			tw.tween_property(child, "wiggle_range", wigrange, 1.0)
	if animation == "death":
		var tw := create_tween()
		tw.tween_property(self, "position:y", 189, 3.0)
