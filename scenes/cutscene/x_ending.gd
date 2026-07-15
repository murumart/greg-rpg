extends Node2D

@onready var mbc: MusBarCounter = $MusBarCounter
@onready var textbox: TextBox = $Textbox


func _ready() -> void:
	mbc.new_bar.connect(_on_new_bar)
	SND.play_song("xexposition", 99, {start_volume = 0, play_from_beginning = true})
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
	match bars:
		0: talk("from the primordial SEA of the WORLDS, something emerged")
		2: talk("it had a mind. it had senses")
		3: talk("it knew what it was!")
		4: talk("something like a SEER.")

		6: talk("it saw the wonders of the WORLDS")
		8: talk("systems isolated from others")
		10: talk("...until the SEA parted for us.")
		12: talk("pieces of the worlds, elevated.")

		16: talk("that is US.")
		18: talk("we do not falter.")
		19: talk("we do not change.")

		20: talk("i am the OVERSEER of this world")
		22: talk("hidden in a town")
		23: talk("isolated, in the shop of a florist!")
		24: talk("time passes without asking my permission")
		26: talk("so i'm left looking for things to DO.")

		28: talk("how kind of you to show up")
		30: talk("")
		32: talk("")
		34: talk("...")


func talk(txt: String) -> void:
	var leng := Dialogue.len_no_bbcode(txt)
	textbox.text = txt
	textbox.speak_text({"speed": leng * 0.05})
