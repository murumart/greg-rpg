extends Node2D

@onready var starmap := $Starmap
@onready var starmap_2 := $Starmap2

@onready var stone_column: StaticBody2D = $StoneColumn
@onready var stone_column_2: StaticBody2D = $StoneColumn2

var progress: int:
	set(to): DAT.set_data("sg_b4_piuzzl2_progress", to)
	get: return DAT.get_data("sg_b4_piuzzl2_progress", 0)


func _ready() -> void:
	starmap.finished.connect(func() -> void:
		if not bool(progress & 0b1):
			SND.play_sound(preload("res://sounds/gui/rock_slide.tres"), {volume = 10, bus = "ECHO"})
		progress |= 0b1
		go()
	)
	starmap_2.finished.connect(func() -> void:
		if not bool(progress & 0b10):
			SND.play_sound(preload("res://sounds/gui/rock_slide.tres"), {volume = 10, bus = "ECHO"})
		progress |= 0b10
		go()
	)


func go() -> void:
	if progress & 0b1:
		stone_column.global_position = Vector2(999, 999)
	if progress & 0b10:
		stone_column_2.global_position = Vector2(999, 9991)
