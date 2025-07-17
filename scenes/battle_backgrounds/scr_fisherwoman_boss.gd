extends "res://scenes/battle_backgrounds/scr_lakeside.gd"

const Blocks = preload("res://scenes/fishing/blocks.gd")

@onready var blocks: Node2D = $Node2D/Blocks



func _ready() -> void:
	super()
	blocks.speed = 30.0
	bpm = 159.0
	blocks.state = Blocks.FG.States.MOVE
