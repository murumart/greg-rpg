extends Node2D

@onready var mbc: MusBarCounter = $MusBarCounter
@onready var textbox: TextBox = $Textbox

const PITCH := 0.89


func _ready() -> void:
	mbc.new_bar.connect(_on_new_bar)
	mbc.bpm *= PITCH
	SND.play_song("xexposition", 99, {pitch_scale = PITCH, start_volume = 0, play_from_beginning = true})
	_on_new_bar(0)


# bars:
# 8: first drums go
# 16: start of motif
# 20: bass comes in
# 24: repeat again
# 28: repeat again section
# 32: last section

func _on_new_bar(bars: int) -> void:
	prints("bar", bars)
	const COOL := 16
	match bars:
		0: talk("from the primordial SEA of the WORLDS, something emerged")
		2: talk("it had a mind. it had senses.")
		4: talk("it knew what it was! something like a WATCHER.")
		6: talk("something like an OVERSEER.")

		8: talk("it saw the wonders of the WORLDS")
		10: talk("how isolated they were")
		12: talk("...until the SEA parted for us.")
		14: talk("pieces of the worlds, elevated.")

		COOL + 0: talk("that is US.")
		COOL + 1: talk("we do not forget.")
		COOL + 2: talk("we do not falter.")
		COOL + 3: talk("we do not change.")

		COOL + 4: talk("i am the OVERSEER of this world")
		COOL + 6: talk("hidden in a town")
		COOL + 7: talk("isolated, in the shop of a florist!")
		COOL + 8: talk("time passes without asking my permission")
		COOL + 10: talk("when all i am supposed to do is watch...")

		COOL + 12: talk("i'm left looking for things to DO.")
		COOL + 14: talk("adjustments here, there, in history")
		COOL + 16: talk("and the POWER, for little people, like you")
		COOL + 17: talk("to change it too, for the better.")

		COOL + 18: talk("i thank YOU")
		COOL + 19: talk("the last perfect change")
		COOL + 20: talk("was to undo their power.")
		COOL + 22: talk("and to let the world live on...")


func talk(txt: String) -> void:
	var leng := Dialogue.len_no_bbcode(txt)
	textbox.text = txt
	textbox.speak_text({"speed": leng * 0.05})
