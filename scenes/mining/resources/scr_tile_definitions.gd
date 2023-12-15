extends RefCounted

static var INVALID := Tile.new(-1)
static var STONE := Tile.new(0).add_atlas(Vector2i(0, 1)).add_atlas(Vector2i(1, 0)).add_atlas(Vector2i(1, 1)).set_flammability(0.002)
static var DIRT := Tile.new(1).set_flammability(0.01).set_terrain(0)
static var WATER := Tile.new(2)
static var GAS := Tile.new(3).set_flammability(1.0)
static var FIRE := Tile.new(4).add_atlas(Vector2i(1, 3))

static var IDS := {
	0: STONE,
	1: DIRT,
	2: WATER,
	3: GAS,
	4: FIRE,
}

static func tile(id: int) -> Tile:
	return IDS.get(id, INVALID)


class Tile:
	var source := -1
	var terrain := -1
	var _random_atlases: Array[Vector2i] = [Vector2i(0, 0)]
	var atlas: Vector2i:
		get:
			return _random_atlases.pick_random()
	var flammability := 0.0
	
	func _init(_source: int) -> void:
		source = _source
	
	func add_atlas(_atlas: Vector2i) -> Tile:
		_random_atlases.append(_atlas)
		return self
	
	func set_flammability(_flammability: float) -> Tile:
		flammability = _flammability
		return self
	
	func set_terrain(_terrain: int) -> Tile:
		terrain = _terrain
		return self
	
	func _to_string() -> String:
		return str({"source": source, "terrain": terrain, "atlases": _random_atlases, "flammability": flammability})
