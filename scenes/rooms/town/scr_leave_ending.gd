extends Node2D

@onready var approach_area := $ApproachArea as Area2D


func _ready() -> void:
	if DAT.get_character("greg").level >= 7:
		queue_free()
		return
	if DAT.get_data("leave_ending_offered", false):
		queue_free()
		return
	approach_area.body_entered.connect(func(_a):
		approach_area.queue_free()
		SOL.dialogue("leave_ending_check")
		DAT.set_data("leave_ending_offered", true)
		SOL.dialogue_closed.connect(func():
			if SOL.dialogue_choice == &"yes":
				# TODO put something normal here
				$"../../Greg".queue_free()
		, CONNECT_ONE_SHOT)
	)
