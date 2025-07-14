class_name StatusEffectPayload extends BattlePayload

@export_group("Modifiers")
@export var health_strength_modifier := 1.0
@export var magic_strength_modifier := 1.0


func get_payload_b(effect: BattleStatusEffect) -> BattlePayload:
	var eff_strength := effect.strength
	var eff_duration := effect.duration
	return _convert_to_payload(eff_strength, eff_duration)


func get_payload_e(effect: StatusEffect) -> BattlePayload:
	var eff_strength := effect.strength
	var eff_duration := effect.duration
	return _convert_to_payload(eff_strength, eff_duration)


func _convert_to_payload(eff_strength: float, _eff_duration: int) -> BattlePayload:
	var pl := BattlePayload.new()
	pl.type = BattlePayload.Types.EFFECT
	for n: StringName in FIELDS:
		if n == &"effects":
			pl.effects.append_array(effects)
			continue
		pl.set(n, get(n))
	pl.set_health(lerpf(health, eff_strength * health, health_strength_modifier))
	pl.set_health_percent(lerpf(health_percent, eff_strength * health_percent, health_strength_modifier))
	pl.set_max_health_percent(lerpf(max_health_percent, eff_strength * max_health_percent, health_strength_modifier))
	pl.set_magic(lerpf(magic, eff_strength * magic, magic_strength_modifier))
	pl.set_magic_percent(lerpf(magic_percent, eff_strength * magic_percent, magic_strength_modifier))
	pl.set_max_magic_percent(lerpf(max_magic_percent, eff_strength * max_magic_percent, magic_strength_modifier))
	return pl
