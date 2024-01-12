extends Node2D

var section := -1
@onready var timer: Timer = $Timer
@onready var label: Label = $Label


func _ready() -> void:
	timer.timeout.connect(timeout)
	timeout()
	
	
func _process(delta: float) -> void:
	label.text = ""
		


func timeout() -> void:
	section += 1
	print(section)
	match section:
		0:
			timer.start(54.6667)
		1:
			timer.start(22.32713)
		2:
			timer.start(27.9997)
		3:
			timer.start(22.34027)
			section = -1
