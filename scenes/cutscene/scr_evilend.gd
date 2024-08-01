extends Node2D

@onready var textbox: TextBox = $Textbox
var bpm := 111.0
var bps := 60.0 / bpm
const SONG_BARS_LENGTH := 56


func _ready() -> void:
	SND.play_song("evil_end")


var last_mod := 0.0
func _process(delta: float) -> void:
	if not is_instance_valid(SND.current_song_player):
		return
	var curr_pos := SND.current_song_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	var mod := fmod(curr_pos, bps)
	#print("mod ", mod)
	if mod < last_mod:
		new_beat()
	last_mod = mod


var beat := 0
func new_beat() -> void:
	beat += 1
	if beat % 4 == 0:
		new_bar()


var bar := 0
func new_bar() -> void:
	bar += 1
	print("bar: ", bar)
	do_something()


func do_something() -> void:
	match bar:
		1:
			talk("with the end of your influence, greg was left with no directions to continue.")
		4:
			talk("left alone, he thus resumed with the only thing he had learned from this journey:")
		6:
			talk("growing in might through violence.")
		8:
			talk("")
		16:
			talk("amassing more and more spirit power as he plowed through the land")
		18:
			talk("death and ruin followed in his wake - what else?")
		20:
			talk("")
		24:
			talk("his path was cut short while he was crossing over to the northern continent.")
		26:
			talk("in a display of heroism, the guards of the country stood against him.")
		28: 
			talk("while not a mission without losses, greg was in the end outsmarted")
		30:
			talk("and cast away into the folds of time, severed from destiny itself")
		32:
			talk("never able to truly leave a mark on this world.")
		36:
			talk("and then there was peace again, for a fleeting moment.")
		38:
			talk("")
			var cds := preload("res://scenes/gui/scn_end_credits.tscn").instantiate()
			SOL.add_ui_child(cds)


func talk(text: String, speed := 1.0) -> void:
	textbox.text = text
	textbox.visible_ratio = 0.0
	textbox.speak_text({"speed": (20.0 / text.length() * 0.5) * speed})

