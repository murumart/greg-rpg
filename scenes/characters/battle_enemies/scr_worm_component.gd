class_name WormComponent extends Node

enum MoveModes {PATH, DISTANCE}
@export var move_mode := MoveModes.PATH

@export var segments: Node2D
@export var pos_base: Node2D

@export var seg_distance: float = 4.0
@export var seg_close_speed: float = 180.0

var positions: Array[Vector2] = []
var _time: float
var _last_pos_append: float


func _physics_process(delta: float) -> void:
	var children := segments.get_children()
	match move_mode:
		MoveModes.PATH:
			_path_move(children, delta)
		MoveModes.DISTANCE:
			_distance_move(children, delta)


func _path_move(children: Array, delta: float) -> void:
	for c in children.size():
		if positions.size() - 1 < c:
			positions.push_front(pos_base.global_position)
		var child := children[c] as Node2D
		var cgp := child.global_position
		var pos := positions[c]
		child.global_position = cgp.move_toward(pos, delta * seg_close_speed)
	_time += delta * 60
	if _time / seg_distance >= 1.0:
		positions.push_front(pos_base.global_position)
		positions.pop_back()
		_time = 0.0


func _distance_move(children: Array, delta: float) -> void:
	var last_child: Node2D = null
	for c in children.size():
		var child := children[c] as Node2D
		if not last_child:
			last_child = pos_base
		var cgp := child.global_position
		var lcgp := last_child.global_position
		if cgp.distance_to(lcgp) > seg_distance * 2.5:
			child.global_position = cgp.move_toward(lcgp, delta * seg_close_speed)
			last_child = child
