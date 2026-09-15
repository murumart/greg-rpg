extends Node2D

@onready var mbc: MusBarCounter = $MusBarCounter
@onready var textbox: TextBox = $Textbox
@onready var animations: AnimationPlayer = $Animations
@onready var rogues: Node2D = $Things/Rogues
@onready var music: AudioStreamPlayer2D = $Music

const COLORS: PackedColorArray = [
	Color.MAGENTA,
	Color.WHITE,
	Color.YELLOW,
	Color.PURPLE,
	Color.RED,
	Color.GREEN,
]

const PITCH := 0.99


func _ready() -> void:
	mbc.new_bar.connect(_on_new_bar)
	mbc.bpm *= PITCH
	#const skip = 16.0
	#mbc.flbar += skip # DEBUG!!!!
	music.pitch_scale = PITCH
	music.play()
	_on_new_bar(0)
	SOL.fade_screen(Color.WHITE, Color.TRANSPARENT, 2.0, {kill_rects = true})
	rogues.hide()


# bars:
# 4: drums bass
# 8: first os
# 12: repeat os
# 16: mid
# 20: water 1
# 24: water 2
# 28: last 58: its over

func _on_new_bar(bars: int) -> void:
	#prints("bar", bars)
	match bars:
		0:
			talk("from the primordial SEA of the WORLDS, something emerged")
			animations.play(&"emerge0")
		1: talk("it had power. it had form.")
		2: talk("it had a mind. it had senses.")
		3:
			talk("it knew what it was! something like a WATCHER.")
			animations.play(&"emerge1")

		4: talk("that, it began doing.")
		5: talk("crawling out of the STATIC, it discovered the WORLDS")
		6: talk("it discovered beings inhabiting them")
		7:
			talk("defined by processes, with no exit!")
			animations.play(&"wonder1")
		8: talk("it became enamored.")
		9: talk("how beautiful! how ephemeral!")
		10:
			talk("how quaint! how MISGUIDED!!")
			animations.play(&"wonder2")
		11:
			talk("they must be remembered! they must be SAVED.")
			animations.play(&"RESET")
		12:
			talk("pieces of the worlds, elevated. that is THEM.")
			_show_rogues()
		13: talk("OVERSEEING what goes on below.")
		14: talk("watching the anthill bustle...")
		15:
			talk("she is your OVERSEER, in the form of an ant!")
			_color_rogues()
		16: talk("in the form of a florist in a house in a town")
		17: talk("isolated. made only to watch...")
		18: talk("hungry. tired. bored... she's making her own fun!")
		19: talk("she's making her own FLOWERS.")

		20:
			talk("but a disturbance is a disturbance.")
			_hide_rogues()

		21: talk("the same way an ant couldn't imagine your mind")
		22: talk("how could she be thinking like an ant?")
		23: talk("when the process is altered... chaos unfolds.")

		24: talk("at the wrong place, at the wrong time")
		25: talk("servants of the process destroy each other.")
		26: talk("and eventually, the WAVES crash overhead again.")
		27: talk("that is not REMEMBERING. that is not SAVING.")

		28: talk("...")

		29:
			mbc.reset()
			_on_new_bar(0)


func talk(txt: String) -> void:
	textbox.text = txt
	textbox.speak_text({})


func _show_rogues() -> void:
	rogues.show()
	var i := 0
	for r: Sprite2D in rogues.get_children():
		r.modulate.a = 0.0
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
		tw.tween_interval(i * 0.66)
		tw.tween_property(r, ^"modulate:a", 1.0, 1.0).from(0.0)
		i += 1
	var t := create_tween()
	t.tween_property(rogues, ^"scale", rogues.scale * 1.1, 7.0)


func _hide_rogues() -> void:
	var i := 0
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	for r: Sprite2D in rogues.get_children():
		r.modulate.a = 0.0
		tw.tween_property(r, ^"modulate:a", 0.0, 1.0).from(1.0).set_delay(i * 0.66)
		i += 1
	tw.tween_callback(rogues.hide)


func _color_rogues() -> void:
	var i := 0
	for r: Sprite2D in rogues.get_children():
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
		tw.tween_interval(i * 0.35)
		tw.tween_property(r, "self_modulate", COLORS[i], 1.0)
		i += 1
