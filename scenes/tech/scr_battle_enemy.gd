extends BattleActor
class_name BattleEnemy

@export var effect_center := Vector2i()
@export var animator : AnimationPlayer

var healing_spirits : Array[Spirit]
var hurting_spirits : Array[Spirit]
var buffing_spirits : Array[Spirit]
var debuffing_spirits : Array[Spirit]

@export_group("Behaviour")
@export_range(0.0, 1.0) var healing_threshold := 0.0


func act() -> void:
	super.act()
	
	if randf() >= 0.5:
		attack(reference_to_opposing_array.pick_random() if reference_to_actor_array.size() > 0 else null)
	else:
		use_spirit(0, self)
	print(actor_name, " acting finished!")


func hurt(amount: float) -> void:
	super.hurt(amount)
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
