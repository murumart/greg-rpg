extends RefCounted

static var INVALID := Tile.new(Vector2i(0, 0))
static var STONE := Tile.new(Vector2i(0, 0)).add_atlas(Vector2i(0, 1)).add_atlas(Vector2i(1, 0)).add_atlas(Vector2i(1, 1)).set_flammability(0.002)
static var WATER := Tile.new(Vector2i(0, 2))
static var GAS := Tile.new(Vector2i(1, 2)).set_flammability(1.0)
static var FIRE := Tile.new(Vector2i(0, 3)).add_atlas(Vector2i(1, 3))
static var DIRT := Tile.new(Vector2i(0, 0)).set_flammability(0.01)

static var IDS := {
	0: STONE,
	2: WATER,
	3: GAS,
	4: FIRE,
	5: DIRT
}

static func tile(id: int) -> Tile:
	return IDS.get(id, INVALID)


class Tile:
	var _random_atlases : Array[Vector2i] = []
	var atlas : Vector2i:
		get:
			return _random_atlases.pick_random()
	var flammability := 0.0
	
	func _init(_atlas: Vector2i) -> void:
		_random_atlases.append(_atlas)
	
	func add_atlas(_atlas: Vector2i) -> Tile:
		_random_atlases.append(_atlas)
		return self
	
	func set_flammability(_flammability: float) -> Tile:
		flammability = _flammability
		return self
