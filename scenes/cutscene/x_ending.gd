extends Node2D

@onready var mbc: MusBarCounter = $MusBarCounter
@onready var textbox: TextBox = $Textbox


func _ready() -> void:
	mbc.new_bar.connect(_on_new_bar)
	SND.play_song("secret_garden", 99, {start_volume = 0, skip_to = 2.44})
	talk("from the primordial sea of the WORLDS, something emerged")


func _on_new_bar(bars: int) -> void:
	prints("bar", bars)
	match bars:
		2:
			talk("it knew what it was!")
		3:
			talk("something like a SEER.")
		4: talk("it found others like it, and not quite")
		6: talk("beings of mind and soul")
		8: talk("it elevated some")
		10: talk("that is what forms US.")
		11: talk("we do not falter.")
		12: talk("we do not change.")
		13: talk("but the WORLDS very much do.")
		14: talk("...")
		16: talk("")


func talk(txt: String) -> void:
	var leng := Dialogue.len_no_bbcode(txt)
	textbox.text = txt
	textbox.speak_text({"speed": leng * 0.05})
