func hr(actor: BattleActor, container: BattleStatusEffect, attack_gender: int, damage_amount: float) -> float:
	var amt := damage_amount
	SND.play_sound(preload("res://sounds/spirit/splash_attack.ogg"),
			{"pitch_scale": 0.9, "volume": 2, "bus": "ECHO"})
	damage_amount += amt * (1 + (container.strength * 4))
	if attack_gender == Genders.FLAMING:
		damage_amount *= 0.5
	elif attack_gender == Genders.ELECTRIC:
		damage_amount *= 2
	SOL.vfx(
		"splash",
		actor.global_position + Vector2(randf_range(-4, 4), -16),
		{"parent": actor})
	return damage_amount - amt
