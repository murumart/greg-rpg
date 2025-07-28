extends BattleEnemy

var battle: Battle
var mayor: BattleActor


func act() -> void:
	print(turn)
	if turn == 7:
		SND.play_sound(preload("res://sounds/spirit/spirit_name_found.ogg"), {pitch_scale = 2.0})
		for i in 3:
			spawn_wisp()
			SND.play_sound(preload("res://sounds/spirit/spirit_equip.ogg"), {pitch_scale = 1.0 + i * 0.1})
			await Math.timer(0.2)
	elif turn == 14:
		SND.play_sound(preload("res://sounds/spirit/spirit_name_found.ogg"), {pitch_scale = 4.0})
		for i in 6:
			spawn_wisp()
			SND.play_sound(preload("res://sounds/spirit/spirit_equip.ogg"), {pitch_scale = 1.3 + i * 0.1})
			await Math.timer(0.2)
		if is_instance_valid(mayor) and mayor.character.health > 0:
			var dlg := DialogueBuilder.new().set_char("scooterer")
			dlg.al("there's too many of them!! we're being overwhelmed!!")
			dlg.al("there is nothing we can do............")
			await dlg.speak_choice()
	turn_finished()


func spawn_wisp() -> BattleEnemy:
	var actor: BattleEnemy
	actor = load(DIR.enemy_scene_path(&"wisp")).instantiate()
	actor.load_character(&"wisp")
	battle.add_actor(actor, Battle.Teams.ENEMIES)
	actor.global_position = global_position
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(actor, ^"position", Vector2.from_angle(randf() * TAU) * randf_range(16, 28), 1.0)
	if is_instance_valid(mayor):
		actor.extra_targets.append(mayor)
	return actor
