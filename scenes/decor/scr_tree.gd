@tool
extends Node2D

@export_enum("kuusk", "mänd", "tooming", "kadak", "toone") var type : int = 0 : set = set_type
const TYPES_SIZE := 4
@export var randomise_trees := false: set = activate_randomise_trees


func set_type(to: int) -> void:
	var sprite : Sprite2D = $Sprite
	sprite.region_rect.position.x = 16 + to * 48
	type = to


func activate_randomise_trees(_to: bool) -> void:
	if not Engine.is_editor_hint(): return
	if not is_visible_in_tree(): return
	if not is_inside_tree(): return
	for i in get_tree().get_nodes_in_group("trees"):
		i.set_type(randi() % TYPES_SIZE)
		i.scale.x = signf(randf_range(-1, 1)) * 1
