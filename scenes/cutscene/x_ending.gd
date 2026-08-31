extends Node2D

@onready var mbc: MusBarCounter = $MusBarCounter
@onready var textbox: TextBox = $Textbox
@onready var animations: AnimationPlayer = $Animations
@onready var rogues: Node2D = $Things/Rogues

const COLORS: PackedColorArray = [
	Color.MAGENTA,
	Color.WHITE,
	Color.YELLOW,
	Color.PURPLE,
	Color.RED,
	Color.GREEN,
]

const PITCH := 1.0


func _ready() -> void:
	mbc.new_bar.connect(_on_new_bar)
	mbc.bpm *= PITCH
	#const skip = 16.0
	#mbc.flbar += skip # DEBUG!!!!
	SND.play_song("xexposition", 99, {skip_to = 0, pitch_scale = PITCH, start_volume = 0})
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
	prints("bar", bars)
	match bars:
		0:
			talk("from the primordial SEA of the WORLDS, something emerged")
		1: talk("it had power. it had form.")
		2: talk("it had a mind. it had senses.")
		3: talk("it knew what it was! something like a WATCHER.")

		4: talk("that, it began doing.")
		5: talk("crawling out of the STATIC, it discovered the WORLDS")
		6: talk("it discovered beings inhabiting them")
		7: talk("defined by processes, with no exit!")
		8: talk("it became enamored.")
		9: talk("how beautiful! how ephemeral!")
		10: talk("how quaint! how MISGUIDED!!")
		11: talk("they must be remembered! they must be SAVED.")
		12: talk("pieces of the worlds, elevated. that is US.")
		13: talk("OVERSEEING what goes on below.")
		14: talk("watching the anthill bustle...")
		15: talk("i am your OVERSEER, in the form of an ant!")
		16: talk("in the form of a florist in a house in a town")
		17: talk("isolated. made only to watch...")
		18: talk("hungry. tired. bored... i'm making my own fun!")
		19: talk("i'm making my own FLOWERS.")

		20: talk("but a disturbance is a disturbance.")
		21: talk("the same way an ant couldn't imagine my mind")
		22: talk("how could i be thinking like an ant?")
		23: talk("when the process is altered... chaos unfolds.")

		24: talk("at the wrong place, at the wrong time")
		25: talk("servants of the process destroy each other.")
		26: talk("and eventually, the WAVES crash overhead again.")
		27: talk("that is not REMEMBERING. that is not SAVING.")

		28: talk("...unless, i do it like this.")

		29:
			LTS.gate_id = &"afterexpo"
			LTS.level_transition("res://scenes/rooms/scn_room_grandma_house_inside.tscn")

		#COOL + 0:
			#talk("that is US.")
#
		#COOL + 1:
			#talk("we do not forget.")
#
		#COOL + 2:
			#talk("we do not falter.")
		#COOL + 3: talk("we do not change.")
#
		#COOL + 4:
			#rogues.hide()
			#talk("i am the OVERSEER of this world")
#
		#COOL + 6: talk("hidden in a town")
		#COOL + 7: talk("isolated, in the shop of a florist!")
		#COOL + 8: talk("time passes without asking my permission")
		#COOL + 10: talk("when all i am supposed to do is watch...")
#
		#COOL + 11: talk("i'm left looking for things to DO.")
		#COOL + 12: talk("adjustments here, there, in history")
		#COOL + 14: talk("and the POWER, for little people, like you")
		#COOL + 16: talk("to change it too, for the better.")
#
		#COOL + 18: talk("i thank YOU")
		#COOL + 19: talk("the last perfect change")
		#COOL + 20: talk("was to undo their power.")
		#COOL + 22: talk("and to let the world live on...")


func talk(txt: String) -> void:
	var leng := Dialogue.len_no_bbcode(txt)
	textbox.text = txt
	textbox.speak_text({"speed": leng * 0.05})


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


func _color_rogues() -> void:
	var i := 0
	for r: Sprite2D in rogues.get_children():
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
		tw.tween_interval(i * 0.35)
		tw.tween_property(r, "self_modulate", COLORS[i], 1.0)
		i += 1
