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
@onready var timer: Timer = $Timer
@onready var label: Label = $Label
@onready var mbc := $MusBarCounter as MusBarCounter


func _ready() -> void:
	timeout()
	SND.play_song("vampire_fight")


func _process(delta: float) -> void:
	label.text = "
fsec: %s
section: %s
beat: %s/%s
bar: %s/%s" % [fsec, section, mbc.beats, mbc.flbeat, mbc.bars, mbc.flbar]
	if fsec >= SECTION_CHANGES[section]:
		timeout()
	fsec += delta


func timeout() -> void:
	section = wrapi(section + 1, 0, 13)
	print("section: ", section)
	match section:
		0:
			fsec = 0.0
			mbc.reset_floats()
			mbc.reset_measures()
			mbc.beats_per_bar = 5
			print("loop")
		7:
			mbc.reset_floats()
			mbc.reset_measures()
			mbc.beats_per_bar = 4
		9:
			mbc.reset_floats()
			mbc.reset_measures()
			mbc.beats_per_bar = 5
		11:
			mbc.reset_floats()
			mbc.reset_measures()
			mbc.beats_per_bar = 4
