extends Node2D

@onready var obstacles: Array[Node2D] = [
	$Obs1,
	$Obs2,
	$Obs3,
]

var obstacles_cleared: int:
	get: return DAT.get_data("sg_b_2_obstacles_cleared", 0)
	set(to): DAT.set_data("sg_b_2_obstacles_cleared", to)


func _ready() -> void:
	%Starmap1.finished.connect(func() -> void:
		if obstacles_cleared == 0:
			SND.play_sound(preload("res://sounds/sg/target.ogg"))
		obstacles_cleared = 1
		_remve_objstacles())
	%Starmap2.finished.connect(func() -> void:
		if obstacles_cleared == 1:
			SND.play_sound(preload("res://sounds/sg/target.ogg"))
		obstacles_cleared = 2
		_remve_objstacles())
	_remve_objstacles()


func _remve_objstacles() -> void:
	for i in range(0, obstacles_cleared):
		if is_instance_valid(obstacles[i]):
			obstacles[i].queue_free()
