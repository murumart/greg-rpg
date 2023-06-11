extends BattleEnemy

var here := true: set = set_here
var time_away := 0


func set_here(to: bool) -> void:
	print("set here to ", to)
	here = to
	accessible = to
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
	
	if time_away > 2 and not here:
		here = true
	elif here and randf() < 0.85 and time_away < -1:
		here = false
