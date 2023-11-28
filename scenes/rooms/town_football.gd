extends Node2D

@onready var is_visible: VisibleOnScreenNotifier2D = $"../IsFootballVisible"

@onready var baller_1: CharacterBody2D = $"Baller1"
@onready var baller_2: CharacterBody2D = $"Baller2"

@onready var ballers := [baller_1, baller_2]


func _ready() -> void:
	is_visible.screen_exited.connect(_screen_exited)
	is_visible.screen_entered.connect(_screen_entered)
	#_screen_exited()


func _screen_entered() -> void:
	show()
	for b in ballers:
		b.set_physics_process(true)


func _screen_exited() -> void:
	hide()
	for b in ballers:
		b.set_physics_process(false)
