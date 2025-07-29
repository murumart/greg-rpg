extends BattleEnemy

signal pls_x

var battle: Battle
var mayor: BattleActor
var children: Array[BattleActor]


func act() -> void:
	if done: return
	print(turn)
	if turn == 6:
		SND.play_sound(preload("res://sounds/spirit/spirit_name_found.ogg"), {pitch_scale = 2.0})
		for i in 4:
			spawn_wisp()
			SND.play_sound(preload("res://sounds/spirit/spirit_equip.ogg"), {pitch_scale = 1.0 + i * 0.1})
			await Math.timer(0.2)
	elif turn > 7 and not has_wisps():
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
			done = true
			pls_x.emit()
			return
	turn_finished()


var done := false
func hurt(amt: float, _gnd: int) -> void:
	super(amt, _gnd)
	if character.health <= 0.0 and not done:
		pls_x.emit.call_deferred()
		done = true
	if character.health_perc() <= 0.5:
		for w in children:
			w.hurt(2**8, Genders.VAST)


func has_wisps() -> bool:
	return not children.filter(func(a: BattleActor) -> bool: return is_instance_valid(a) and a.state != States.DEAD).is_empty()


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
	children.append(actor)
	return actor


func _spirit_scooter_overrun_used_on() -> void:
	if is_instance_valid(mayor) and mayor.character.health > 0:
		var dlg := DialogueBuilder.new().set_char("scooterer")
		dlg.al("nice going, son!!")
		dlg.al("with enough of that attack, we can shut this thing down!!")
		await dlg.speak_choice()
