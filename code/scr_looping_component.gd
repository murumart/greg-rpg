extends Node

# loops a node2d around a specific length of whatever,

@export var loop_range_min := 0
@export var loop_range_max := 160
@export var target: Node2D


func _ready() -> void:
	if not target:
		printerr("no target")
		return


func _physics_process(_delta: float) -> void:
	target.global_position.x = wrapf(target.global_position.x, loop_range_min, loop_range_max)
