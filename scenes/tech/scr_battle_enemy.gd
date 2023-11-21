extends BattleActor
class_name BattleEnemy

# enemies in battle

enum Intents {ATTACK, BUFF, DEBUFF, HEAL, FLEE, MAX_ACTION}
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
# how low the health can go before starts healing/fleeing
@export_range(0.0, 1.0) var toughness := 0.25
# how likely to heal other members of team
@export_range(0.0, 1.0) var altruism := 0.5
# how likely to deviate from default intent
@export_range(0.0, 1.0) var innovation := 0.75
# how likely to use spirits instead of attacking or using items
@export_range(0.0, 1.0) var vaimulembesus := 0.85
@export_enum("Attack", "Buff", "Debuff", "Heal") var default_intent : int = Intents.ATTACK
@export var auto_ai := true
@export var can_flee := false
@export_group("Other")
@export_range(0.0, 10.0) var xp_multiplier := 1.0

var last_intent : Intents


func _ready() -> void:
	animate("idle")
	super._ready()
	# sorting the spirits
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
	# auto ai can be turned off for scripted battles and such
	if not auto_ai:
		return
	ai_action()


func ai_action() -> void:
	var team := reference_to_team_array.duplicate()
	# intent is what the enemy will do
	var intent := default_intent
	# try finding a suitable act
	for i in FIND_SUITABLE_ACT_TRIES:
		if randf() <= innovation:
			intent = (randi() as Intents) % Intents.MAX_ACTION
		var target : BattleActor
		# spirits are appended to and then selected from this
		var spirit_pocket : Array[String] = []
		# first the enemy tries to choose a spirit to do the thing
		# if it's too expensive/vaimulembesus check fails, it will do items
		# (or attack, if currently attacking)
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
								return # fantastic 8 tab indents
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
					spirit_pocket.shuffle()
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
					spirit_pocket.shuffle()
					for s in spirit_pocket:
						if DAT.get_spirit(s).cost <= character.magic:
							use_spirit(s, target)
							return
				for s in character.inventory:
					if DAT.get_item(s).use == Item.Uses.DEBUFFING:
						use_item(s, target)
						return
			Intents.HEAL:
				# lowest health in front
				team.sort_custom(sort_by_health)
				target = team[0] if not has_status_effect(&"confusion") else pick_target()
				# if too tough, don't heal
				if target == self and target.character.health_perc() > 1.0 - toughness:
					continue
				# if target not self and not altruistic enough, don't heal them
				if target != self and target.character.health_perc() > altruism:
					continue
				if randf() <= vaimulembesus and healing_spirits.size() > 0:
					spirit_pocket.append_array(healing_spirits)
					spirit_pocket.shuffle()
					for s in spirit_pocket:
						if DAT.get_spirit(s).cost <= character.magic:
							use_spirit(s, target)
							return
				for s in character.inventory:
					if DAT.get_item(s).use == Item.Uses.HEALING:
						use_item(s, target)
						return
			Intents.FLEE:
				if not can_flee: continue
				var en : Character = reference_to_opposing_array.pick_random().character
				if (character.health_perc() < 1.0 - toughness and
				randf() < 1.0 - toughness and
				character.health_perc() < en.health_perc() and
				character.level < en.level):
					flee()
					return
	print("could not find suitable action")
	turn_finished()


func hurt(amount: float, gnd: int) -> void:
	super(amount, gnd)
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


func flee() -> void:
	animate("flee")
	super.flee()


# random targets (and account for confusion)
func pick_target(who: int = 0) -> BattleActor:
	if has_status_effect(&"confusion"):
		return reference_to_actor_array.pick_random()
	if who == TEAM:
		return reference_to_team_array.pick_random()
	if who == SELF:
		return self
	if reference_to_opposing_array.size() > 0:
		return reference_to_opposing_array.pick_random()
	return null


func animate(what: String) -> void:
	# custom animations using animationplayer
	if animator:
		if animator.has_animation(what):
			animator.play(what)
			if animator.has_animation("idle") and not what in ["death", "flee"]:
				animator.queue("idle")
			return
	# default animations using tweens
	# we animate the first child if it exists
	var animatable : Node2D
	if self.get_child(0) is Node2D:
		animatable = self.get_child(0)
	if not is_instance_valid(animatable): return
	match what:
		"hurt":
			var tw := create_tween()
			var tw2 := create_tween()
			tw.tween_property(animatable, "modulate", Color(1.2, 0.8, 0.8), 0.1)
			tw2.tween_property(animatable, "scale:y", 0.9, 0.1)
			tw.tween_property(animatable, "modulate", Color(1, 1, 1), 0.1)
			tw2.tween_property(animatable, "scale:y", 1.1, 0.1)
			tw2.tween_property(animatable, "scale:y", 1, 0.2)
		"heal":
			var tw := create_tween()
			tw.tween_property(animatable, "modulate", Color(0.8, 1.2, 0.8), 0.1)
			tw.tween_property(animatable, "modulate", Color(1, 1, 1), 0.1)
		"attack", "use_spirit", "use_item":
			var tw := create_tween()
			tw.tween_property(animatable, "scale:y", 0.9, 0.04)
			tw.tween_property(animatable, "scale:y", 1.1, 0.1)
			tw.tween_property(animatable, "scale:y", 1.0, 0.2)
		"death":
			var tw := create_tween().set_trans(Tween.TRANS_EXPO).set_parallel(true)
			tw.tween_property(animatable, "modulate", Color(1.0, 0.8, 0.8, 0.6), 1.0)
			tw.tween_property(self, "global_position:y", 200, 3.0)
		"flee":
			var tw := create_tween()
			tw.tween_property(animatable, "scale", Vector2(-1.2, 0.8), 0.4)
			tw.tween_property(animatable, "global_position:x", -300, 0.7)


func sort_by_health(a: BattleActor, b: BattleActor) -> bool:
	return a.character.health_perc() < b.character.health_perc()


