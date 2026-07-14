extends Node2D

@onready var mbc: MusBarCounter = $MusBarCounter
@onready var textbox: TextBox = $Textbox


func _ready() -> void:
	mbc.new_bar.connect(_on_new_bar)
	SND.play_song("xexposition", 99, {start_volume = 0, play_from_beginning = true})
	_on_new_bar(0)


func _on_new_bar(bars: int) -> void:
	prints("bar", bars)
	match bars:
		0: talk("from the primordial SEA of the WORLDS, something emerged")
		4: talk("it had a mind. it had senses")
		6: talk("it knew what it was!")
		7: talk("something like a SEER.")

		8: talk("it saw the wonders of the WORLDS")
		10: talk("systems isolated from others")
		12: talk("...until the SEA parted for us.")
		14: talk("pieces of the worlds, elevated.")

		16: talk("that is US.") # start of cool
		18: talk("we do not falter.")
		19: talk("we do not change.")

		20: talk("i am the OVERSEER of this world") # start of bass
		22: talk("hidden in a town")
		23: talk("isolated, in the shop of a florist!")
		24: talk("time passes without asking my permission") # 25 second
		26: talk("so i'm left looking for things to DO.") # 26

		28: talk("how kind of you to show up") # 28 last section 1
		30: talk("")
		32: talk("") # last section 2
		34: talk("...")


func talk(txt: String) -> void:
	var leng := Dialogue.len_no_bbcode(txt)
	textbox.text = txt
	textbox.speak_text({"speed": leng * 0.05})
