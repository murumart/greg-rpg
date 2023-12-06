@tool
extends Node2D

# gates between rooms in the overworld

signal entered

@export_group("Technical")
@export_node_path("Area2D") var area_path : NodePath
@export_node_path("CollisionShape2D") var collision_shape_path : NodePath
@export_node_path("Marker2D") var spawn_point_path : NodePath

@export_group("")
@export var destination := &""
@export var gate_id := &""
@export var extents := Vector2i(8, 8): set = set_extents

@export var spawnpoint := Vector2i(0, 0):
	set(to):
		spawnpoint = to
		if get_node_or_null(spawn_point_path):
			get_node(spawn_point_path).position = to


func set_extents(to: Vector2i) -> void:
	extents = to
	if get_node_or_null(collision_shape_path):
		get_node(collision_shape_path).shape.extents = to


func _enter_tree() -> void:
	add_to_group("room_gates")


func _ready() -> void:
	if Engine.is_editor_hint(): return
	var area : Area2D = get_node_or_null(area_path)
	if area:
		area.body_entered.connect(_on_area_entered)


# when the player enters the gate area
func _on_area_entered(body: Node2D) -> void:
	if body is PlayerOverworld:
		var player := body as PlayerOverworld
		if player.state == PlayerOverworld.States.NOT_FREE_MOVE: return
		if DIR.room_exists(destination):
			# set the gate id
			LTS.gate_id = gate_id
			# and off we go
			LTS.level_transition(DIR.room_scene_path(destination))
		entered.emit()


func apply_spawn_point(player: PlayerOverworld) -> void:
	if LTS.gate_id == gate_id:
		player.global_position = get_node(spawn_point_path).global_position
