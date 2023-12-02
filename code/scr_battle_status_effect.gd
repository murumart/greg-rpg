class_name BattleStatusEffect extends RefCounted

var name := &""
var duration: int = 1
var strength: float = 1.0


static func add(actor: BattleActor, eff: StatusEffect) -> BattleStatusEffect:
	var neweff := BattleStatusEffect.new()
	neweff.set_name(eff.name)
	neweff.set_duration(eff.duration)
	neweff.set_strength(eff.strength)
	if eff.duration < -1:
		neweff.name += &"_immunity"
		neweff.duration = -neweff.duration
		actor.remove_status_effect(eff.name)
	if eff.duration == -1:
		actor.remove_status_effect(eff.name)
		return null
	if actor.is_immune_to(neweff.name):
		neweff._immune_text(actor)
		return null
	if actor.has_status_effect(neweff.name):
		var oldeff : BattleStatusEffect = actor.get_status_effect(neweff.name)
		oldeff.duration = ceili((oldeff.duration + neweff.duration) / 2.0)
		oldeff.strength = floorf((oldeff.strength + neweff.strength) / 2.0)
		return null
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


func added(actor: BattleActor) -> void:
	match name:
		&"little:":
			actor.scale *= 0.25
		&"ghostly":
			self.set_meta(&"last_gender", actor.gender)
			actor.gender = Genders.GHOST


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
		actor.hurt(clampf(actor.character.health * 0.08, 1, 25), Genders.FLAMING)
		SOL.vfx(&"battle_burning",
			actor.global_position + SOL.SCREEN_SIZE / 2 +
			Vector2(randf_range(-2, 2), randf_range(-2, 2)), {"parent": actor})
		SND.play_sound(preload("res://sounds/fire.ogg"), {pitch = 2.0})
	
	if name == &"regen":
		actor.heal(strength * 5)
	
	if name == &"inspiration":
		actor.character.magic += strength * 2


func removed(actor: BattleActor) -> void:
	match name:
		&"little":
			actor.scale *= 4
		&"ghostly":
			actor.gender = get_meta(&"last_gender")


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
		actor.parentless_effcenter(),
		{
			text = "%s%s %s" % [
				Math.sign_symbol(strength),
				str(absf(strength)) if strength != 1 else "",
				name.replace("_", " ")
			],
			color = Color.YELLOW, speed = 0.5
		}
	)


func _immune_text(actor: BattleActor) -> void:
	SOL.vfx(
		"damage_number",
		actor.parentless_effcenter(),
		{
			text = "immune!",
			color = Color.YELLOW, speed = 0.5
		}
	)


func _to_string() -> String:
	return str("BattleStatusEffect " + name + " lvl " + str(strength) + " " + str(duration) + " turn(s) left")
