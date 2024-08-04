extends Node2D

@onready var textbox: TextBox = $Textbox
var bpm := 111.0
var bps := 60.0 / bpm
const SONG_BARS_LENGTH := 56

@onready var imgs := Math.child_dict($CenterContainer/Images)


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
			var tw := create_tween()
			imgs.directionless.show()
			tw.tween_property(imgs.directionless, "modulate:a", 1.0, 2.0).from(0.0)
		4:
			talk("left alone, he thus resumed with the only thing he had learned from this journey:")
			var tw := create_tween()
			tw.tween_property(imgs.directionless, "modulate:a", 0.0, 2.0)
			tw.tween_callback(imgs.directionless.hide)
		6:
			talk("growing in might through violence.")
			var tw := create_tween()
			imgs.violence.show()
			tw.tween_property(imgs.violence, "modulate:a", 1.0, 1.0).from(0.0)
		8:
			talk("")
			imgs.destruction.show()
			imgs.violence.hide()
			var tw := create_tween()
			tw.tween_property(imgs.destruction, "position:x", -130, 30.0)
		16:
			talk("amassing more and more spirit power as he plowed through the land")
		18:
			talk("death and ruin followed in his wake - what else?")
		20:
			talk("")
		24:
			talk("his path was cut short while he was crossing over to the northern continent.")
			imgs.sea.show()
			var tw := create_tween()
			tw.tween_property(imgs.destruction, "modulate:a", 0.0, 2.0)
			tw.parallel().tween_property(imgs.sea, "modulate:a", 1.0, 2.0).from(0.0)
			tw.parallel().tween_property(imgs.sea.texture, "region:position:x", 599940, 9999)
			tw.parallel().tween_property(imgs.sea.texture, "region:position:y", -399960, 9999)
		26:
			talk("in a display of heroism, the guards of the country stood against him.")
		28: 
			talk("while not a mission without losses, greg was in the end outsmarted")
		30:
			talk("and cast away into the folds of time, severed from destiny itself")
			var tw := create_tween()
			tw.tween_property(imgs.sea, "modulate:a", 0.0, 4.0)
			imgs.dead.show()
			tw.parallel().tween_property(imgs.dead, "modulate:a", 1.0, 4.0).from(0.0)
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

