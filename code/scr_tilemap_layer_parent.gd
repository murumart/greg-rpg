class_name TilemapLayerParent extends Node2D

var layers: Array[TileMapLayer] = []


func _ready() -> void:
	layers.append_array(get_children())


func update_layers() -> void:
	layers.clear()
	layers.append_array(get_children())


func get_cell_tile_data(layer: int, coords: Vector2i) -> TileData:
	return layers[layer].get_cell_tile_data(coords)


func set_layer_enabled(layer: int, enabled: bool) -> void:
	layers[layer].enabled = enabled
	layers[layer].visible = enabled


func get_layers_count() -> int:
	return layers.size()
