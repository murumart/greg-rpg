extends Node2D

@onready var approach_area := $ApproachArea as Area2D


func _ready() -> void:
	if DAT.get_data("leave_ending_offered", false):
		queue_free()
		return
	approach_area.body_entered.connect(func(_a):
		approach_area.queue_free()
		SOL.dialogue("leave_ending_check")
		DAT.set_data("leave_ending_offered", true)
		SOL.dialogue_closed.connect(func():
			if SOL.dialogue_choice == &"yes":
				$"../../Greg".queue_free()
				await Math.timer(3.0)
				SND.play_song("")
				LTS.level_transition("res://scenes/cutscene/scn_leave_ending.tscn")
		, CONNECT_ONE_SHOT)
	)

const AFTER := "



"
