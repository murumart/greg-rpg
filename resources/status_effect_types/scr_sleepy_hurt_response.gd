func hr(actor: BattleActor, _container: BattleStatusEffect, attack_gender: int, damage_amount: float) -> float:
	var amt := damage_amount
	actor.remove_status_effect(&"sleepy")
	actor.message.emit("%s woke up!" % actor.actor_name)
	damage_amount *= 1.8
	if attack_gender == Genders.BRAIN:
		damage_amount *= 1.8
	return damage_amount - amt
