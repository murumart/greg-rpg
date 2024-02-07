class_name BattleStatusEffect extends RefCounted

var name := &""
var duration: int = 1
var strength: float = 1.0


static func add(actor: BattleActor, eff: StatusEffect) -> BattleStatusEffect:
	var neweff := BattleStatusEffect.new()
	neweff.set_name(eff.name)
	neweff.set_duration(eff.duration)
	neweff.set_strength(eff.strength)
	# duration -1 means curing or removing some sort of effect
	if eff.duration == -1:
		var oldeff := actor.get_status_effect(neweff.name)
		if oldeff:
			oldeff._removed_text(actor)
		actor.remove_status_effect(eff.name)
		return null
	# duration < -1 means an immunity effect instead
	if eff.duration < -1:
		neweff.name += &"_immunity"
		neweff.duration = -neweff.duration
		actor.remove_status_effect(eff.name)
	if actor.is_immune_to(neweff.name):
		neweff._immune_text(actor)
		return null
	# we have both status effects
	if actor.has_status_effect(neweff.name):
		var oldeff := actor.get_status_effect(neweff.name)
		var olds := oldeff.strength
		var addition := BattleStatusEffect.plus(neweff, oldeff)
		actor.remove_status_effect(eff.name)
		if not addition:
			oldeff._removed_text(actor)
			return null
		oldeff._adjusted_text(actor, (addition.strength if addition else 0.0) - olds)
		print(actor.actor_name, " changed effect ", oldeff, " -> ", addition)
		return addition
	neweff._add_text(actor)
	neweff.added(actor)
	if not neweff.name in DAT.get_data("known_status_effects", []):
		DAT.appenda("known_status_effects", neweff.name)
	return neweff


static func add_s(
		actor: BattleActor, e_name: StringName, e_duration: int, e_strength: float
	) -> BattleStatusEffect:
	return BattleStatusEffect.add(actor,
		StatusEffect.new().set_effect_name(
			e_name).set_duration(e_duration).set_strength(e_strength))


func set_name(x: StringName) -> BattleStatusEffect:
	name = x
	return self


func set_duration(x: int) -> BattleStatusEffect:
	duration = x
	return self


func set_strength(x: float) -> BattleStatusEffect:
	strength = x
	return self


static func plus(a: BattleStatusEffect, b: BattleStatusEffect) -> BattleStatusEffect:
	var u := BattleStatusEffect.new()
	if a.name != b.name:
		return null
	u.name = a.name
	u.strength = ceilf((a.strength + b.strength) / 2.0)
	if u.strength == 0:
		return null
	if u.strength == a.strength or u.strength == b.strength:
		u.strength += sign(u.strength)
	u.duration = ceili((a.duration + b.duration) / 2.0)
	if u.duration <= 0:
		return null
	if u.duration == a.duration or u.duration == b.duration:
		u.duration += sign(u.duration)
	return u


func added(actor: BattleActor) -> void:
	match name:
		&"little":
			actor.scale *= 0.25


func turn(actor: BattleActor) -> void:
	duration -= 1
	if duration <= 0:
		actor.remove_status_effect(name)

	if name == &"coughing":
		# coughing damage is applied by a separate battle actor because why not
		var cougher := BattleActor.new()
		cougher.character = Character.new()
		cougher.character.attack = strength * 2
		actor.add_child(cougher)
		cougher.attack(actor)
		SND.play_sound(preload("res://sounds/spirit/airspace_violation.ogg"), {"volume": -3})
		cougher.queue_free()

	if name == &"poison":
		actor.hurt(strength * 1.3, Genders.NONE)

	if name == &"fire":
		actor.hurt(
			clampf(actor.character.health * 0.08 * ceilf(strength / 32.0), 1, 25),
			Genders.FLAMING)
		SOL.vfx(&"battle_burning",
			actor.global_position + SOL.SCREEN_SIZE / 2 +
			Vector2(randf_range(-2, 2), randf_range(-2, 2)), {"parent": actor})
		SND.play_sound(preload("res://sounds/fire.ogg"), {pitch_scale = 2.0})

	if name == &"regen":
		actor.heal(strength * 5)

	if name == &"inspiration":
		actor.character.magic += strength * 2


func hurt_damage(amount: float, gender: int, actor: BattleActor) -> float:
	var amt := amount
	match name:
		&"sleepy":
			actor.remove_status_effect(&"sleepy")
			actor.message.emit("%s woke up!" % actor.actor_name)
			amount *= 1.8
			if gender == Genders.BRAIN:
				amount *= 1.8
		&"sopping":
			SND.play_sound(preload("res://sounds/spirit/fish_attack.ogg"),
				{"pitch_scale": 1.3, "volume": 2})
			amount += amt * (0.4 + (strength * 0.2))
			if gender == Genders.FLAMING:
				amount *= 0.5
			elif gender == Genders.ELECTRIC:
				amount *= 1.5
			SOL.vfx(
				"sopping",
				actor.global_position + Vector2(randf_range(-4, 4), -16),
				{"parent": actor})

	return amount - amt


func attack_bonus(actor: BattleActor) -> float:
	if name == &"attack":
		return strength
	if name == &"electric":
		return 6 + strength
	return 0


func defense_bonus(actor: BattleActor) -> float:
	if name == &"defense":
		return strength
	return 0


func speed_bonus(actor: BattleActor) -> float:
	if name == &"speed":
		return strength
	return 0


func removed(actor: BattleActor) -> void:
	match name:
		&"little":
			actor.scale *= 4


func visuals(actor: BattleActor) -> void:
	if randf() <= 0.02 and name == &"fire":
		SOL.vfx("battle_burning",
			actor.global_position + Vector2(randf_range(-4, 4),
				randf_range(-8, 16)), {"parent": actor})
		var tw := actor.create_tween().set_trans(Tween.TRANS_QUINT)
		var rand := randf_range(0.5, 1.0)
		tw.tween_property(actor, "modulate",
			Color(randf_range(1.0, 1.5), rand, rand, 1.0), rand)
	if randf() <= 0.03 and name == &"sleepy":
		SOL.vfx(
			"sleepy",
			actor.global_position + Vector2(randf_range(-4, 4),
				randf_range(-16, 0)), {"parent": actor})
	if randf() <= 0.04 and name == &"sopping":
		SOL.vfx(
			"sopping",
			actor.global_position + Vector2(randf_range(-4, 4),
				randf_range(-16, 0)), {"parent": actor})


func _add_text(actor: BattleActor) -> void:
	SOL.vfx(
		"damage_number",
		actor.parentless_effcenter() - Vector2(0, 16),
		{
			text = "%s%s %s" % [
				Math.sign_symbol(strength),
				str(absf(strength)) if strength != 1 else "",
				name.replace("_", " ")
			],
			color = Color.YELLOW, speed = 0.5
		}
	)
	actor.emit_message("@%s %s%s %s" % [
		actor.actor_name,
		Math.sign_symbol(strength),
		str(absf(strength)) if strength != 1 else "",
		name.replace("_", " ")
	])


func _adjusted_text(actor: BattleActor, streng: float) -> void:
	SOL.vfx(
		"damage_number",
		actor.parentless_effcenter() - Vector2(0, 24),
		{
			text = "%s%s %s" % [
				Math.sign_symbol(streng),
				str(absf(streng)) if streng != 1 else "",
				name.replace("_", " ")
			],
			color = Color.LIGHT_YELLOW, speed = 0.5
		}
	)
	actor.emit_message("@%s %s%s %s" % [
		actor.actor_name,
		Math.sign_symbol(streng),
		str(absf(strength)) if strength != 1 else "",
		name.replace("_", " ")
	])


func _removed_text(actor: BattleActor) -> void:
	SOL.vfx(
		"damage_number",
		actor.parentless_effcenter() - Vector2(0, 8),
		{
			text = "no %s" % [
				name.replace("_", " ")
			],
			color = Color.DIM_GRAY, speed = 0.5
		}
	)
	actor.emit_message("@%s no %s" % [actor.actor_name, name.replace("_", " ")])


func _immune_text(actor: BattleActor) -> void:
	SOL.vfx(
		"damage_number",
		actor.parentless_effcenter() - Vector2(0, 16),
		{
			text = "immune!",
			color = Color.YELLOW, speed = 0.5
		}
	)
	actor.emit_message("@%s immune!" % actor.actor_name)


func _to_string() -> String:
	return str("BattleStatusEffect " + name + " lvl " + str(strength) + " " + str(duration) + " turn(s) left")
