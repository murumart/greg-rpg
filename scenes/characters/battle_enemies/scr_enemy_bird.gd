extends EnemyAnimal

var here := true: set = set_here
var time_away := 0
@export var max_time_away := 2
@export var min_time_here := 2


func set_here(to: bool) -> void:
	here = to
	accessible = to
	xp_multiplier = 2.0 if not to else 1.0
	animate("swoop_in" if to else "swoop_out")
	time_away = 0
	emit_message(("%s swoops in!" if to else "%s swoops out!") % actor_name)


func ai_action() -> void:
	if here:
		super.ai_action()
	else:
		turn_finished()
	
	if here: time_away -= 1
	else: time_away += 1
	
	if time_away >= max_time_away and not here:
		here = true
	elif here and randf() < 0.85 and time_away < -min_time_here:
		here = false
