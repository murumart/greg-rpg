extends BattleEnemy

const WigglerType := preload("res://scenes/tech/scr_line_wiggler.gd")


func ai_action() -> void:
	if (turn + 1) % 4 == 0:
		use_spirit("catcall", self)
		return
	super()


func animate(animation: StringName, queue_idle := true) -> void:
	super(animation, queue_idle)
	if animation in ["attack", "use_spirit", "use_item"]:
		wiggle()
	if animation == "death":
		var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(self, "position:y", 189, 8.0)
		SND.play_sound(preload("res://sounds/spirit/dish_end.ogg"))
		wiggle(128)


func wiggle(size := 56.0) -> void:
	for child in $OutlineMe.get_children():
		child = child as WigglerType
		if not child:
			continue
		var wigrange: Vector2 = child.wiggle_range
		var tw := create_tween()
		tw.tween_property(child, "wiggle_range", Vector2(size, size), 0.1)
		tw.tween_property(child, "wiggle_range", wigrange, 1.0)
