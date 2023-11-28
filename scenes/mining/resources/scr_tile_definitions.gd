extends RefCounted

static var STONE := Tile.new(Vector2i(0, 0)).add_atlas(Vector2i(0, 1)).add_atlas(Vector2i(1, 0)).add_atlas(Vector2i(1, 1))
static var WATER := Tile.new(Vector2i(0, 2))
static var GAS := Tile.new(Vector2i(1, 2))


class Tile:
	var _random_atlases : Array[Vector2i] = []
	var atlas : Vector2i:
		get:
			return _random_atlases.pick_random()
	
	func _init(_atlas: Vector2i) -> void:
		_random_atlases.append(_atlas)
	
	func add_atlas(_atlas: Vector2i) -> Tile:
		_random_atlases.append(_atlas)
		return self
