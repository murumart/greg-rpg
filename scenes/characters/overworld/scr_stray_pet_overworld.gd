extends OverworldCharacter


func interacted() -> void:
	if not RunFlags.animals_battled_changed:
		DAT.incri("stray_animals_fought", battle_info.enemies.size())
		RunFlags.animals_battled_changed = true
	super()


func _car_collision_response(car: CarOverworld) -> void:
	SOL.vfx("dustpuff", global_position, {"parent": get_parent()})
	SOL.vfx("bangspark", global_position, {"parent": get_parent()})
	SND.play_sound_2d(preload("res://sounds/attack_blunt.ogg"), global_position)
	var tw := create_tween()
	set_collision_mask_value(2, false)
	set_physics_process(false)
	var moveto := (car.global_position - car.target).normalized() * car.speed
	tw.tween_property(self, "global_position", moveto, 1.0)
	tw.tween_callback(queue_free)
