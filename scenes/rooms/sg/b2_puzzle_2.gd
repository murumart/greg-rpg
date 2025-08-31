extends Node2D

@onready var pizzle_column: StaticBody2D = $PizzleColumn


func _ready() -> void:
	pizzle_column.finished.connect(func() -> void:
		preload("res://scenes/rooms/sg/b2_obstacles.gd").obstacles_cleared = 3
	)
