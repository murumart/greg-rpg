func hr(actor: BattleActor, container: BattleStatusEffect, attack_gender: int, damage_amount: float) -> float:
	var amt := damage_amount
	SND.play_sound(preload("res://sounds/spirit/fish_attack.ogg"),
			{"pitch_scale": 1.3, "volume": 2})
	damage_amount += amt * (0.2 + (container.strength * 0.15))
	if attack_gender == Genders.FLAMING:
		damage_amount *= 0.5
	elif attack_gender == Genders.ELECTRIC:
		damage_amount *= 1.2
	SOL.vfx(
		"sopping",
		actor.global_position + Vector2(randf_range(-4, 4), -16),
		{"parent": actor})
	return damage_amount - amt
