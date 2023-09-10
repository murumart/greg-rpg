class_name ForestPath extends Room

enum {NORTH, SOUTH, EAST, WEST}

const HAS_ENTRANCE := [
	[0, 1, 3, 4], # NORTH
	[0, 1, 5, 6], # SOUTH
	[1, 2, 4, 6], # EAST
	[1, 2, 3, 5], # WEST
]
const TREE := preload("res://scenes/decor/scn_tree.tscn")
const TREE_COUNT := 45
const LOCATION_TESTS := 10
const TRASH := preload("res://scenes/decor/scn_trash_bin.tscn")
var trash_count := 10
const ENEMY := preload("res://scenes/characters/overworld/scn_wild_lizard_overworld.tscn")
var enemy_count := 10

@onready var greg := $Greg as PlayerOverworld
@onready var paths: TileMap = $Tilemaps/Paths
var enabled_layer := 0
var used_poses := PackedVector2Array()

@onready var current_room := DAT.get_data(
	"current_forest_rooms_traveled", 0) as int
var inversion := false

@export_group("Curves")
@export var trash_amount_curve : Curve
@export var trash_silver_item_chance_curve : Curve


func _ready() -> void:
	super._ready()
	
	for i in $Gates.get_child_count():
		($Gates.get_child(i) as Area2D).body_entered.connect(gate_entered.bind(
			i).unbind(1))
		if DAT.get_data("forest_last_gate_entered", -1) == i:
			if not LTS.gate_id == LTS.GATE_EXIT_BATTLE:
				greg.global_position = $Gates.get_child(dir_oppos(i)).get_child(
					1).global_position
	if not LTS.gate_id == LTS.GATE_EXIT_BATTLE:
		load_layout()
		trees()
		bins()
		enemies()
	else:
		load_from_save()
	
	# debug
	if DAT.get_character("greg").level == 1:
		DAT.get_character("greg").level_up(59)


func gate_entered(which: int) -> void:
	print("gate ", which)
	LTS.gate_id = &"forest_transition"
	if which != dir_oppos(DAT.get_data("forest_last_gate_entered", -1)):
		DAT.set_data("forest_last_gate_entered", which)
		LTS.level_transition("res://scenes/rooms/scn_room_forest.tscn")
		DAT.incri("total_forest_rooms_traveled", 1)
		DAT.incri("current_forest_rooms_traveled", 1)
	else:
		leave()


func load_layout() -> void:
	var last := DAT.get_data("forest_last_gate_entered", -1) as int
	var entrance := dir_oppos(last)
	var layout := HAS_ENTRANCE[entrance].pick_random() as int
	if randf() <= 0.95 and (entrance == EAST or entrance == WEST):
		layout = HAS_ENTRANCE[last].pick_random()
		paths.scale.x = -1
	for i in paths.get_layers_count():
		paths.set_layer_enabled(i, false)
	if layout in [0, 1, 2]:
		if randf() <= 0.5:
			paths.scale.x = -1
		if randf() <= 0.05:
			paths.scale.y = -1
			inversion = true
	paths.set_layer_enabled(layout, true)
	enabled_layer = layout


func load_from_save() -> void:
	var d := DAT.get_data("forest_save", {}) as Dictionary
	for i in paths.get_layers_count():
		paths.set_layer_enabled(i, false)
	paths.set_layer_enabled(d.layout, true)
	paths.scale = d.pscale
	for t in d.trees.keys():
		var tree := TREE.instantiate()
		add_child(tree)
		tree.type = d.trees[t]
		tree.global_position = t
	for b in d.bins.keys():
		var bin := TRASH.instantiate()
		add_child(bin)
		bin.global_position = b
		bin.item = d.bins[b].item
		bin.silver = d.bins[b].silver
		bin.full = d.bins[b].full
		bin.add_to_group("bins")
	# do not load enemies after a fight
	for e in d.enemies:
		pass
	current_room = d.room_nr


func rand_pos() -> Vector2:
	var pos := Vector2()
	for j in LOCATION_TESTS:
		pos.x = randf_range(-18, 17)
		pos.y = randf_range(-16, 15)
		var td := paths.get_cell_tile_data(enabled_layer, Vector2i(pos))
		if (not td or td.terrain != 1) and \
		not pos in used_poses:
			break
	used_poses.append(pos)
	return pos


func trees() -> void:
	for i in TREE_COUNT:
		var tree := TREE.instantiate()
		add_child(tree)
		var pos := rand_pos()
		tree.global_position = pos * 16
		tree.type = randi() % tree.TYPES_SIZE


func bins() -> void:
	trash_count = roundi(trash_amount_curve.sample_baked(
		current_room / 100.0) * randf())
	for i in trash_count:
		var trash := TRASH.instantiate()
		trash.save = false
		add_child(trash)
		var pos := rand_pos()
		trash.global_position = pos * 16
		bin_loot(trash)


func enemies() -> void:
	enemy_count = clampi(current_room / 12, 1, 12)
	for i in enemy_count:
		var enemy := ENEMY.instantiate()
		enemy.difficulty = current_room / 100.0
		enemy.chase_target = greg
		add_child(enemy)
		var pos := rand_pos().floor()
		enemy.global_position = pos * 16
		enemy.add_to_group("enemies")


func dir_oppos(which: int) -> int:
	if which == NORTH: return SOUTH
	if which == SOUTH: return NORTH
	if which == EAST: return WEST
	if which == WEST: return EAST
	return -1


func bin_loot(bin: TrashBin) -> void:
	bin.replenish_seconds = -1
	bin.save = false
	bin.add_to_group("bins")
	if randf() <= 0.25: return
	if randf() <= 0.25:
		bin.full = false
		return
	if randf() <= trash_silver_item_chance_curve.sample_baked(
		current_room / 100.0):
		# silver
		bin.silver = current_room * ((randi() % 2) + 1)
		return
	# item
	bin.item = "gummy_worm"


func leave() -> void:
	DAT.set_data("last_forest_gate_entered", -1)
	DAT.set_data("current_forest_rooms_traveled", 0)
	LTS.level_transition("res://scenes/rooms/scn_room_town.tscn")


func _save_me() -> void:
	if LTS.gate_id == LTS.GATE_ENTER_BATTLE:
		print("forest saving data!")
		var forest_save := {}
		var trees_dict := {}
		var bins_dict := {}
		var enemies_dict := {}
		for tree in get_tree().get_nodes_in_group("trees"):
			tree = tree as TreeDecor
			trees_dict[tree.global_position] = tree.type
		for bin in get_tree().get_nodes_in_group("bins"):
			bin = bin as TrashBin
			bins_dict[bin.global_position] = {
				"item": bin.item,
				"silver": bin.silver,
				"full": bin.full
			}
		for enemy in get_tree().get_nodes_in_group("enemies"):
			enemy = enemy as OverworldCharacter
			enemies_dict[enemy.name] = {
				"pos": enemy.global_position,
			}
		forest_save = {
			"layout": enabled_layer,
			"pscale": paths.scale,
			"room_nr": current_room,
			"trees": trees_dict,
			"bins": bins_dict,
			"enemies": enemies_dict
		}
		DAT.set_data("forest_save", forest_save)

