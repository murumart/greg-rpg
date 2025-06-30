extends OverworldCharacter

var prog := DAT.get_data("lost_guy_progress", 0) as int
var increases := 0


func _ready() -> void:
	super()

	if prog >= 15:
		queue_free()
	inspected.connect(func():
		if not visible:
			return
		if increases < 2:
			prog += 1
			increases += 1
		default_lines.clear()
		default_lines.append("lost_guy_" + str(prog))
		DAT.set_data("lost_guy_progress", prog)
		SOL.dialogue_closed.connect(func():
			if not prog >= 15:
				return
			hide()
			SND.play_song("")
			$AudioStreamPlayer.play()
			$AudioStreamPlayer.finished.connect(queue_free)
		, CONNECT_ONE_SHOT)
	)
