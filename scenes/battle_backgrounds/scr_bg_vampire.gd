extends Node2D

const SECTION_CHANGES: Array[float] = [
	13.333, # 0
	26.667, # 1; pads come in
	40.000, # 2
	43.333, # 3; prebreak 1
	46.667, # 4; breakdown 1
	50.000, # 5; break from breakdowm
	54.667, # 6; breakdown 2
	65.333, # 7; first pop
	76.994, # 8
	90.318, # 9
	104.993, # 10
	115.656, # 11; second pop
	127.334 # 12
]

var fsec := 0.0
var section := -1
@onready var anim := $Anim as AnimationPlayer
@onready var mbc := $MusBarCounter as MusBarCounter


func _ready() -> void:
	timeout()
	SND.play_song("vampire_fight", 1.0, {start_volume = 0, play_from_beginning = true})


func _process(delta: float) -> void:
	if fsec >= SECTION_CHANGES[section]:
		timeout()
	fsec += delta


func timeout() -> void:
	section = wrapi(section + 1, 0, 13)
	match section:
		0:
			anim.play("RESET")
			anim.seek(99, true)
			fsec = 0.0
			mbc.reset_floats()
			mbc.reset_measures()
			mbc.beats_per_bar = 5
			anim.play("sec1", 1.0)
		1:
			anim.play("sec2", 1.0)
		2:
			anim.play("sec3", 1.0)
		3:
			anim.play("RESET")
			anim.play_backwards("sec1", 0.2)
		4:
			anim.play("sec4")
		5:
			anim.play_backwards("sec2", 0.2)
		6:
			anim.play("RESET")
			anim.play("sec4", 0, 1.0)
		7:
			mbc.reset_floats()
			mbc.reset_measures()
			mbc.beats_per_bar = 4
			anim.play("sec7")
		8:
			anim.play("sec3")
		9:
			anim.play("RESET")
			anim.seek(99, true)
			mbc.reset_floats()
			mbc.reset_measures()
			mbc.beats_per_bar = 5
			anim.play("sec1")
		10:
			anim.play("sec2")
		11:
			mbc.reset_floats()
			mbc.reset_measures()
			mbc.beats_per_bar = 4
			anim.play("sec2")
			anim.seek(99, true)
			anim.play("sec7")
		12:
			anim.play("sec3")
