@tool
class_name PathfindingGridArea extends Node2D

@export var size := Vector2i(8, 8):
	set(to):
		size = to
		queue_redraw()
@export_range(1, 4) var point_density := 1:
	set(to):
		point_density = to
		queue_redraw()
@export_flags_2d_physics var collide_with: int = 0b01

@export var room: Room
@onready var _space_state: PhysicsDirectSpaceState2D = (
		room.get_parent().get_world_2d().direct_space_state)

var _grid := AStarGrid2D.new()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	set_physics_process(false)
	var points := get_point_poses()
	_grid.region = Rect2i(global_position.x, global_position.y,
			size.x * point_density, size.y * point_density)
	_grid.cell_size = Vector2(16, 16)
	_grid.update()
	for pos in points:
		if is_point_collision(pos):
			_grid.set_point_solid(pos, true)


func _draw() -> void:
	draw_rect(Rect2(
			Vector2(-size.x * 0.5, -size.y * 0.5) * 16.0,
			Vector2(size.x, size.y) * 16.0),
			Color(0.5, 0.1, 0.25, 0.5), true)
	draw_rect(Rect2(
			Vector2(-size.x * 0.5, -size.y * 0.5) * 16.0,
			Vector2(size.x, size.y) * 16.0),
			Color(0.5, 0.1, 0.25), false)
	for pos in get_point_poses():
		draw_circle(pos, 1.0,
			Color.FIREBRICK if not is_point_collision(pos) else Color.CYAN)


func _physics_process(_delta: float) -> void:
	queue_redraw()


func get_point_poses() -> Array[Vector2]:
	var poses: Array[Vector2] = []
	var points_y := roundi(size.y * point_density)
	var points_x := roundi(size.x * point_density)
	var posdiff := Vector2(
			global_position.x - int(global_position.x),
			global_position.y - int(global_position.y)
	) * 2.0
	for y: float in points_y:
		for x: float in points_x:
			var xpos := x / point_density
			var ypos := y / point_density
			var pos := (Vector2(xpos, ypos) - size * 0.5) - posdiff
			pos *= 16
			poses.append(pos)
	return poses


func is_point_collision(point: Vector2) -> bool:
	if not is_instance_valid(_space_state):
		return false
	var params := PhysicsPointQueryParameters2D.new()
	params.collision_mask = collide_with
	params.position = to_global(point)
	return not _space_state.intersect_point(params, 5).is_empty()
