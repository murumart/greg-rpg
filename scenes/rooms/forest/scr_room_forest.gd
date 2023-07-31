extends Room

enum {NORTH, SOUTH, EAST, WEST}

const HAS_ENTRANCE := [
	[0, 1, 3, 4], # NORTH
	[0, 1, 5, 6], # SOUTH
	[1, 2, 4, 6], # EAST
	[1, 2, 3, 5], # WEST
]
const TREE := preload("res://scenes/decor/scn_tree.tscn")
const TREE_COUNT := 45
const TREE_LOCATION_TESTS := 10

@onready var greg := $Greg as PlayerOverworld
@onready var paths: TileMap = $Tilemaps/Paths
var enabled_layer := 0


func _ready() -> void:
	super._ready()
	
	for i in $Gates.get_child_count():
		($Gates.get_child(i) as Area2D).body_entered.connect(gate_entered.bind(
			i).unbind(1))
		if DAT.get_data("forest_last_gate_entered", -1) == i:
			greg.global_position = $Gates.get_child(dir_oppos(i)).get_child(
				1).global_position
	load_layout()
	trees()


func gate_entered(which: int) -> void:
	if which != dir_oppos(DAT.get_data("forest_last_gate_entered", -1)):
		DAT.set_data("forest_last_gate_entered", which)
		LTS.level_transition("res://scenes/rooms/scn_room_forest.tscn")
	else:
		LTS.level_transition("res://scenes/rooms/scn_room_town.tscn")


func load_layout() -> void:
	var last := DAT.get_data("forest_last_gate_entered", -1) as int
	var entrance := dir_oppos(last)
	var layout := HAS_ENTRANCE[entrance].pick_random() as int
	for i in paths.get_layers_count():
		paths.set_layer_enabled(i, false)
	paths.set_layer_enabled(layout, true)
	enabled_layer = layout


func trees() -> void:
	var used_poses := PackedVector2Array()
	for i in TREE_COUNT:
		var tree := TREE.instantiate()
		add_child(tree)
		var pos := Vector2()
		for j in TREE_LOCATION_TESTS:
			pos.x = randf_range(-18, 17)
			pos.y = randf_range(-16, 15)
			var td := paths.get_cell_tile_data(enabled_layer, Vector2i(pos))
			if (not td or td.terrain != 1) and \
			not pos in used_poses:
				break
		tree.global_position = pos * 16
		tree.type = randi() % tree.TYPES_SIZE
		used_poses.append(pos)


func dir_oppos(which: int) -> int:
	if which == NORTH: return SOUTH
	if which == SOUTH: return NORTH
	if which == EAST: return WEST
	if which == WEST: return EAST
	return -1

