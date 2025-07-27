extends BattleEnemy

var battle: Battle


func act() -> void:
	turn_finished()
	print(turn)


func spawn_wisp() -> BattleEnemy:
	var actor: BattleEnemy
	actor = load(DIR.enemy_scene_path(&"wisp")).instantiate()
	actor.load_character(&"wisp")
	battle.add_actor(actor, Battle.Teams.ENEMIES)
	actor.global_position = global_position
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(actor, ^"position", Vector2.from_angle(randf() * TAU) * randf_range(16, 28), 1.0)
	for x in extra_targets:
		if x in actor.extra_targets: continue
		actor.extra_targets.append(x)
	return actor
