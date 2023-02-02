@tool
extends Node2D

@export_group("Technical")
@export_node_path("Area2D") var area_path : NodePath
@export_node_path("CollisionShape2D") var collision_shape_path : NodePath
@export_node_path("Marker2D") var spawn_point_path : NodePath

@export_group("")
@export var destination := &""
@export var gate_id := &""
@export var player : PlayerOverworld
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


func _ready() -> void:
	if Engine.is_editor_hint(): return
	var area : Area2D = get_node_or_null(area_path)
	if area:
		area.body_entered.connect(_on_area_entered)
	await get_tree().process_frame
	if LTS.gate_id == gate_id:
		if player and get_node_or_null(spawn_point_path):
			player.global_position = get_node(spawn_point_path).global_position


func _on_area_entered(body: Node2D) -> void:
	if body == player:
		if DIR.file_exists(DIR.room_scene_path(destination)):
			LTS.gate_id = gate_id
			LTS.level_transition(DIR.room_scene_path(destination))

