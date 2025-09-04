extends "res://scenes/rooms/forest/forest_objects/scr_puzzle_column.gd"

@export var exchanges: Array[Exchange]
@export_multiline var override_lines: PackedStringArray

@onready var animator: AnimationPlayer = $Animator

var _override_lines_seen: bool:
	get: return DAT.get_data("pcolumn_%s_in_%s_lines_seen" % [name, LTS.get_current_scene().name], false)
	set(to): DAT.set_data("pcolumn_%s_in_%s_lines_seen" % [name, LTS.get_current_scene().name], to)


func _interacted() -> void:
	animator.play(&"open")
	DAT.capture_player("column")
	await animator.animation_finished
	var inv := ResMan.get_character("greg").inventory
	var dlg := DialogueBuilder.new().set_char("column_talk")
	if not override_lines or _override_lines_seen:
		dlg.add_line(dlg.ml("to love is to change something."))
	else:
		for line in override_lines:
			dlg.al(line)
		_override_lines_seen = true
	await dlg.speak_choice()
	while true:
		var aval_choices: Array[StringName]
		for e in exchanges:
			aval_choices.append(e.title)
		aval_choices.append(&"bye")
		dlg.reset().set_char("column_talk")
		dlg.add_line(dlg.ml("we have work to do, don't we?").schoices(aval_choices))
		var choice := await dlg.speak_choice()
		if choice == &"bye":
			dlg.reset().set_char("column_talk")
			dlg.add_line(dlg.ml([
				"time is irrelevant to meeting me.",
				"has been, will be, me here... but you...?",
				"greetings.",
				"it will have been inevitable.",
				"shan't we meet again?",
			].pick_random()))
			await dlg.speak_choice()
			break
		else:
			var exchange := exchanges[exchanges.find_custom(func(a: Exchange) -> bool: return a.title == choice)]
			exchange.state_criteria()
			exchange.state_returns()
			dlg.reset().set_char("column_talk")
			if exchange.has_input(inv):
				dlg.add_line(dlg.ml("is this your choice?").schoices(["yes", "no"]))
				choice = await dlg.speak_choice()
				dlg.reset().set_char("column_talk")
				if choice == &"yes":
					dlg.add_line(dlg.ml("it approaches its final form."))
					await dlg.speak_choice()
					animator.play(&"transmute")
					await animator.animation_finished
					exchange.exchange(inv)
					#animator.play(&"open")
					#break
				else:
					dlg.add_line(dlg.ml("you're stalling."))
					await dlg.speak_choice()
			else:
				dlg.add_line(dlg.ml("but it is not within your power."))
				await dlg.speak_choice()
	DAT.free_player("column")
	animator.play(&"close")
