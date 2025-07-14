class_name BattleStatusEffect extends RefCounted

var type: StatusEffectType
var duration: int = 1
var strength: float = 1.0


static func add(actor: BattleActor, eff: StatusEffect) -> BattleStatusEffect:
	var neweff := BattleStatusEffect.new()
	neweff.set_type_s(eff.name)
	neweff.set_duration(eff.duration)
	neweff.set_strength(eff.strength)
	# duration -1 means curing or removing some sort of effect
	if eff.duration == -1:
		var oldeff := actor.get_status_effect(neweff.type.s_id)
		if oldeff:
			oldeff._removed_text(actor)
		actor.remove_status_effect(eff.name)
		return null
	# duration < -1 means an immunity effect instead
	if eff.duration < -1:
		neweff.set_type_s(eff.name + "_immunity")
		neweff.duration = - neweff.duration
		actor.remove_status_effect(eff.name)
	if actor.is_immune_to(neweff.type.s_id):
		neweff._immune_text(actor)
		return null
	# we have both status effects
	if actor.has_status_effect(neweff.type.s_id):
		var oldeff := actor.get_status_effect(neweff.type.s_id)
		var olds := oldeff.strength
		var addition := BattleStatusEffect.plus(neweff, oldeff)
		actor.remove_status_effect(eff.name)
		if not addition:
			oldeff._removed_text(actor)
			return null
		oldeff._adjusted_text(actor, (addition.strength if addition else 0.0) - olds)
		if actor._logsalot:
			print(actor.actor_name, " changed effect ", oldeff, " -> ", addition)
		return addition
	neweff._add_text(actor)
	neweff.added(actor)
	if not neweff.type.s_id in DAT.get_data("known_status_effects", []):
		DAT.appenda("known_status_effects", neweff.type.s_id)
	return neweff


static func add_s(
		actor: BattleActor, e_name: StringName, e_duration: int, e_strength: float
	) -> BattleStatusEffect:
	return BattleStatusEffect.add(actor,
		StatusEffect.new().set_effect_name(
			e_name).set_duration(e_duration).set_strength(e_strength))


func set_type_s(x: StringName) -> BattleStatusEffect:
	type = ResMan.get_effect(x)
	return self


func set_duration(x: int) -> BattleStatusEffect:
	duration = x
	return self


func set_strength(x: float) -> BattleStatusEffect:
	strength = x
	return self


static func plus(a: BattleStatusEffect, b: BattleStatusEffect) -> BattleStatusEffect:
	var u := BattleStatusEffect.new()
	if a.type.s_id != b.type.s_id:
		return null
	u.type = a.type
	u.strength = maxf(a.strength, b.strength)
	if sign(a.strength) != sign(b.strength):
		u.strength = a.strength + b.strength
	elif (a.strength < 0 or b.strength < 0) and u.strength > 0:
		u.strength -= minf(a.strength, b.strength)
	if u.strength == 0:
		return null
	if absf(a.strength - b.strength) < 2:
		u.strength += sign(u.strength)
	if a.duration != 1 and b.duration != 1:
		u.duration = ceili((a.duration + b.duration) / 2.0)
	else:
		u.duration = maxi(a.duration, b.duration)
	if u.duration <= 0:
		return null
	if u.duration == a.duration or u.duration == b.duration:
		u.duration += sign(u.duration)
	return u


func added(actor: BattleActor) -> void:
	if type.added_script:
		type.added_script.new().added(actor, self)


func turn(actor: BattleActor) -> void:
	duration -= 1
	if duration <= 0:
		actor.remove_status_effect(type.s_id)
	await type.turn(actor, self)


func hurt_damage(amount: float, gender: int, actor: BattleActor) -> float:
	var amt := amount
	amt += type.actor_hurt_response(actor, self, gender, amount)

	return amt - amount


func attack_bonus(_actor: BattleActor) -> float:
	if not type.turn_payload:
		return 0
	return type.turn_payload.attack_increase * strength


func defense_bonus(_actor: BattleActor) -> float:
	if not type.turn_payload:
		return 0
	return type.turn_payload.defense_increase * strength


func speed_bonus(_actor: BattleActor) -> float:
	if not type.turn_payload:
		return 0
	return type.turn_payload.speed_increase * strength


func removed(actor: BattleActor) -> void:
	if type.removed_script:
		type.removed_script.new().removed(actor, self)


func visuals(actor: BattleActor) -> void:
	type.process_visuals(actor, self)


func _add_text(actor: BattleActor) -> void:
	SOL.vfx(
		"damage_number",
		actor.parentless_effcenter() - Vector2(0, 16),
		{
			text = "%s%s %s" % [
				Math.sign_symbol(strength),
				str(int(absf(strength))) if strength != 1 else "",
				type.name
			],
			color = Color.YELLOW, speed = 0.5
		}
	)
	actor.emit_message("@%s %s%s %s" % [
		actor.actor_name,
		Math.sign_symbol(strength),
		str(int(absf(strength))) if strength != 1 else "",
		type.name
	])


func _adjusted_text(actor: BattleActor, streng: float) -> void:
	if streng == 0:
		return
	SOL.vfx(
		"damage_number",
		actor.parentless_effcenter() - Vector2(0, 24),
		{
			text = "%s%s %s" % [
				Math.sign_symbol(streng),
				str(int(absf(streng))) if streng != 1 else "",
				type.name
			],
			color = Color.LIGHT_YELLOW, speed = 0.5
		}
	)
	actor.emit_message("@%s %s%s %s" % [
		actor.actor_name,
		Math.sign_symbol(streng),
		str(int(absf(streng))) if streng != 1 else "",
		type.name
	])


func _removed_text(actor: BattleActor) -> void:
	SOL.vfx(
		"damage_number",
		actor.parentless_effcenter() - Vector2(0, 8),
		{
			text = "no %s" % [
				type.name
			],
			color = Color.DIM_GRAY, speed = 0.5
		}
	)
	actor.emit_message("@%s no %s" % [actor.actor_name, type.name])


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
	return str("BattleStatusEffect ", type.s_id, " lvl ", strength, " ", duration, " turn(s) left")
