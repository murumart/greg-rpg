extends Node2D

@onready var board: Sprite2D = $Board
@onready var collide: StaticBody2D = $Collide
@onready var pizzle_column := $PizzleColumn

var done: bool:
	set(to): DAT.set_data("sg_b4_piuzzle_done", to)
	get: return DAT.get_data("sg_b4_piuzzle_done", false)


func _ready() -> void:
	board.hide()
	if done:
		go()
		return
	pizzle_column.finished.connect(func() -> void:
		done = true
		SND.play_sound(preload("res://sounds/misc_click.ogg"))
		go()
	)


func go() -> void:
	board.show()
	collide.set_collision_layer_value(1, false)
