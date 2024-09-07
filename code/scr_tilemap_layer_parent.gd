class_name TilemapLayerParent extends Node2D

var layers: Array[TileMapLayer] = []


func _ready() -> void:
	update_layers()


func update_layers() -> void:
	layers.clear()
	layers.append_array(get_children().filter(func(a: Node) -> bool: return a is TileMapLayer))


func get_cell_tile_data(layer: int, coords: Vector2i) -> TileData:
	return layers[layer].get_cell_tile_data(coords)


func set_cells_terrain_connect(
		layer: int, cells: Array[Vector2i],
		terrain_set: int, terrain: int,
		ignore_empty_terrains: bool = true) -> void:
	layers[layer].set_cells_terrain_connect(cells, terrain_set, terrain, ignore_empty_terrains)


func set_layer_enabled(layer: int, enabled: bool) -> void:
	layers[layer].enabled = enabled
	layers[layer].visible = enabled


func set_cell(
		layer: int, coords: Vector2i,
		source_id: int = -1,
		atlas_coords: Vector2i = Vector2i(-1, -1),
		alternative_tile: int = 0) -> void:
	layers[layer].set_cell(coords, source_id, atlas_coords, alternative_tile)


func clear_layer(layer: int) -> void:
	layers[layer].clear()


func get_layers_count() -> int:
	return layers.size()
