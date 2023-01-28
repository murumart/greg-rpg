extends BattleActor
class_name BattleEnemy

enum Actions {ATTACK, BUFF, DEBUFF, HEAL}

@export var effect_center := Vector2i()
@export var animator : AnimationPlayer

var healing_spirits : Array[Spirit]
var hurting_spirits : Array[Spirit]
var buffing_spirits : Array[Spirit]
var debuffing_spirits : Array[Spirit]

@export_group("Behaviour")
@export_range(0.0, 1.0) var healing_threshold := 0.0
@export_range(0.0, 1.0) var altruism := 0.5
@export_range(0.0, 1.0) var innovation := 0.5
@export var default_action := Actions.ATTACK


func act() -> void:
	super.act()
	
	var action := default_action
	var team := reference_to_team_array.duplicate()
	var team_dict := {}
	if altruism:
		team_dict = team_dict_with_health_keys(team)
	
	if randf() >= 0.5:
		if reference_to_opposing_array.size() > 0:
			attack(reference_to_opposing_array.pick_random())
		else:
			turn_finished()
	else:
		turn_finished()
	print(actor_name, " acting finished!")


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


func use_spirit(id: int, subject: BattleActor) -> void:
	animate("use_spirit")
	super.use_spirit(id, subject)


func use_item(id: int, subject: BattleActor) -> void:
	animate("use_item")
	super.use_item(id, subject)


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
