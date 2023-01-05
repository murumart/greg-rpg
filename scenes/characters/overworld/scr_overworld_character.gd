extends CharacterBody2D
class_name OverworldCharacter

@export_group("Nodes")
@export var collision_shape : CollisionShape2D
@export var collision_extents := Vector2i(8, 3): set = _set_collision_extents
@export var interaction_area : Area2D



func _ready() -> void:
	pass


func interacted() -> void:
	pass


func _set_collision_extents(to: Vector2i) -> void:
	collision_extents = to
	if collision_shape:
		collision_shape.shape.size = to
	if interaction_area:
		interaction_area.area_extents.x = to.x + 1
		interaction_area.area_extents.y = to.y + 1
