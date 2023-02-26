extends BattleActor
class_name BattleEnemy

enum Intents {ATTACK, BUFF, DEBUFF, HEAL, MAX_ACTION}
const TEAM := 1
const SELF := 2

@export var effect_center := Vector2i()
@export var animator : AnimationPlayer

const FIND_SUITABLE_ACT_TRIES := 32

var healing_spirits : Array[String]
var hurting_spirits : Array[String]
var buffing_spirits : Array[String]
var debuffing_spirits : Array[String]

@export_group("Behaviour")
@export_range(0.0, 1.0) var toughness := 0.25
@export_range(0.0, 1.0) var altruism := 0.5
@export_range(0.0, 1.0) var innovation := 0.75
@export_range(0.0, 1.0) var vaimulembesus := 1.0
@export_enum("Attack", "Buff", "Debuff", "Heal") var default_intent : int = Intents.ATTACK
@export var auto_ai := true


func _ready() -> void:
	animate("idle")
	super._ready()
	for s in character.spirits:
		var spirit : Spirit = DAT.get_spirit(s)
		if spirit.use == Spirit.Uses.BUFFING:
			buffing_spirits.append(s)
		elif spirit.use == Spirit.Uses.DEBUFFING:
			debuffing_spirits.append(s)
		elif spirit.use == Spirit.Uses.HEALING:
			healing_spirits.append(s)
		elif spirit.use == Spirit.Uses.HURTING:
			hurting_spirits.append(s)


func act() -> void:
	super.act()
	if not auto_ai:
		return
	ai_action()


func ai_action() -> void:
	var team := reference_to_team_array.duplicate()
	var intent := default_intent
	for i in FIND_SUITABLE_ACT_TRIES:
		if randf() <= innovation:
			intent = (randi() as Intents) % Intents.MAX_ACTION
		var target : BattleActor
		var spirit_pocket : Array[String] = []
		match intent:
			Intents.ATTACK:
				target = pick_target()
				if hurting_spirits.size() > 0:
					spirit_pocket.append_array(hurting_spirits)
					spirit_pocket.shuffle()
					if randf() <= vaimulembesus:
						for s in spirit_pocket:
							if DAT.get_spirit(s).cost <= character.magic:
								use_spirit(s, target)
								return
				for s in character.inventory:
					if DAT.get_item(s).use == Item.Uses.HURTING:
						use_item(s, target)
						return
				attack(target)
				return
			Intents.BUFF:
				target = pick_target(SELF)
				if randf() <= altruism: target = pick_target(TEAM)
				if randf() <= vaimulembesus and buffing_spirits.size() > 0:
					spirit_pocket.append_array(buffing_spirits)
					for s in spirit_pocket:
						if DAT.get_spirit(s).cost <= character.magic:
							use_spirit(s, target)
							return
				for s in character.inventory:
					if DAT.get_item(s).use == Item.Uses.BUFFING:
						use_item(s, target)
						return
			Intents.DEBUFF:
				target = pick_target()
				if randf() <= vaimulembesus and debuffing_spirits.size() > 0:
					spirit_pocket.append_array(debuffing_spirits)
					for s in spirit_pocket:
						if DAT.get_spirit(s).cost <= character.magic:
							use_spirit(s, target)
							return
				for s in character.inventory:
					if DAT.get_item(s).use == Item.Uses.DEBUFFING:
						use_item(s, target)
						return
			Intents.HEAL:
				target = pick_target(SELF)
				if character.health_perc() > toughness:
					continue
				if not (1.0 - character.health_perc() < altruism):
					team.sort_custom(sort_by_health)
					target = team[0]
				if randf() <= vaimulembesus and healing_spirits.size() > 0:
					spirit_pocket.append_array(healing_spirits)
					for s in spirit_pocket:
						if DAT.get_spirit(s).cost <= character.magic:
							use_spirit(s, target)
							return
				for s in character.inventory:
					if DAT.get_item(s).use == Item.Uses.HEALING:
						use_item(s, target)
						return
	print("could not find suitable action")
	turn_finished()


func hurt(amount: float) -> void:
	if amount != 0.0: super.hurt(amount)
	if state != States.DEAD:
		animate("hurt")
	else:
		animate("death")


func heal(amount: float) -> void:
	super.heal(amount)
	animate("heal")


func attack(subject: BattleActor) -> void:
	animate("attack")
	super.attack(subject)


func use_spirit(id: String, subject: BattleActor) -> void:
	animate("use_spirit")
	super.use_spirit(id, subject)


func use_item(id: String, subject: BattleActor) -> void:
	animate("use_item")
	super.use_item(id, subject)


func pick_target(who: int = 0) -> BattleActor:
	if is_confused():
		return reference_to_actor_array.pick_random()
	if who == TEAM:
		return reference_to_team_array.pick_random()
	if who == SELF:
		return self
	if reference_to_opposing_array.size() > 0:
		return reference_to_opposing_array.pick_random()
	return null


func animate(what: String) -> void:
	if animator:
		if animator.has_animation(what):
			animator.play(what)
			return
	match what:
		"hurt":
			var tw := create_tween()
			var tw2 := create_tween()
			tw.tween_property(self, "modulate", Color(1.2, 0.8, 0.8), 0.1)
			tw2.tween_property(self, "scale:y", 0.9, 0.1)
			tw.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
			tw2.tween_property(self, "scale:y", 1.1, 0.1)
			tw2.tween_property(self, "scale:y", 1, 0.2)
		"heal":
			var tw := create_tween()
			tw.tween_property(self, "modulate", Color(0.8, 1.2, 0.8), 0.1)
			tw.tween_property(self, "modulate", Color(1, 1, 1), 0.1)
		"attack", "use_spirit", "use_item":
			var tw := create_tween()
			tw.tween_property(self, "scale:y", 0.9, 0.04)
			tw.tween_property(self, "scale:y", 1.1, 0.1)
			tw.tween_property(self, "scale:y", 1.0, 0.2)
		"death":
			var tw := create_tween().set_trans(Tween.TRANS_EXPO).set_parallel(true)
			tw.tween_property(self, "modulate", Color(1.0, 0.8, 0.8, 0.6), 1.0)
			tw.tween_property(self, "global_position:y", 200, 3.0)


func sort_by_health(a: BattleActor, b: BattleActor) -> bool:
	return a.character.health < b.character.health


func team_dict_with_health_keys(team: Array[BattleActor]) -> Dictionary:
	var dict := {}
	for i in team:
		dict[i.character.health] = i
	return dict
