class_name ForestGenerator

enum {NORTH, SOUTH, EAST, WEST}

const HAS_ENTRANCE := [
	[0, 1, 3, 4, 7, 9, 10], # NORTH
	[0, 1, 5, 6, 7, 8, 9], # SOUTH
	[1, 2, 4, 6, 7, 8, 10], # EAST
	[1, 2, 3, 5, 8, 9, 10], # WEST
]

const OBJECT_AMOUNT := 15

const TREE := preload("res://scenes/decor/scn_tree.tscn")
const TREE_COUNT := 45
const LOCATION_TESTS := 20
const TRASH := preload("res://scenes/decor/scn_trash_bin.tscn")
const ENEMY := preload("res://scenes/characters/overworld/scn_wild_lizard_overworld.tscn")
const GREENHOUSE := preload("res://scenes/decor/scn_greenhouse.tscn")
const GreenhouseType := preload("res://scenes/decor/scr_greenhouse.gd")
const GREENHOUSE_INTERVAL := 7
const BOARD_INTERVAL := 3
const VEGET_GREENHOUSE_INTERVAL := 21

const BIN_LOOT := {
	"gummy_worm": 30,
	"eggshell": 6,
	"egg_cooked": 3,
	"egg": 5,
	"lighter": 1,
	"bread": 5,
	"plaster": 3,
	"pills": 6,
	"tape": 1,
	"sugar_lemon": 3,
	"gummy_fish": 8,
	"mueslibar": 1,
}

#const BIN_LOOT := {"gummy_worm": 10} # DEBUG

var forest: ForestPath
var _space_state: PhysicsDirectSpaceState2D
var used_poses := []
var generated_objects := {}


func _init(_forest: ForestPath) -> void:
	forest = _forest
	_space_state = forest.get_world_2d().direct_space_state


func generate() -> void:
	print(" --- generating new room")
	forest.questing.available_quests.clear()
	forest.questing.available_quests_generated = false
	load_layout()
	gen_board()
	gen_bins()
	gen_trees()
	gen_enemies()
	gen_greenhouse()
	gen_objects()
	if randf() < 0.002:
		gen_us()


func rand_pos() -> Vector2:
	var pos := Vector2()
	for j in LOCATION_TESTS:
		pos.x = randi_range(-17, 16)
		pos.y = randi_range(-15, 14)
		if valid_placement_spot(pos):
			break
	return pos


func is_area_free(rect: Rect2i) -> bool:
	for i in rect.size.x:
		for j in rect.size.y:
			var x := i + rect.position.x
			var y := j + rect.position.y
			if not valid_placement_spot(Vector2(x, y)):
				return false
	return true


func valid_placement_spot(pos: Vector2) -> bool:
	var vpos := Vector2i((pos * forest.paths.scale).round())
	if vpos in used_poses:
		return false
	var tds := [
		forest.paths.get_cell_tile_data(forest.enabled_layer, vpos),
		forest.paths.get_cell_tile_data(
			forest.enabled_layer, vpos + Vector2i(forest.paths.scale * Vector2.UP))
	]
	for td: TileData in tds:
		if not (not td or (
			td.terrain != 0 and td.terrain != 1 and td.terrain != 2)):
			return false
	#var params := PhysicsPointQueryParameters2D.new()
	#params.collision_mask = 0b1
	#params.position = forest.to_global(Vector2(vpos * 16.0))
	#var colls := _space_state.intersect_point(params)
	#print(colls)
	#if not colls.is_empty():
		#used_poses.append(vpos)
		#return false
	used_poses.append(vpos)
	return true


func load_layout() -> void:
	var last := DAT.get_data("forest_last_gate_entered", -1) as int
	var entrance := dir_oppos(last)
	var layout := HAS_ENTRANCE[entrance].pick_random() as int
	if randf() <= 0.95 and (entrance == EAST or entrance == WEST):
		layout = HAS_ENTRANCE[last].pick_random()
		forest.paths.scale.x = -1
	for i in forest.paths.get_layers_count():
		forest.paths.set_layer_enabled(i, false)
	if layout in [0, 1, 2, 8, 10] and randf() <= 0.5:
		forest.paths.scale.x = -1
	if randf() <= 0.05 and layout in [0, 1, 2, 7, 9]:
		forest.paths.scale.y = -1
		forest.inversion = true
	forest.paths.set_layer_enabled(layout, true)
	forest.enabled_layer = layout
	print(" ---- chose layout ", layout, " scale is ", forest.paths.scale)


func gen_trees() -> void:
	var amount := TREE_COUNT - forest.questing.get_perk_tree_reduction()
	for i in amount:
		var tree := TREE.instantiate()
		forest.add_child(tree)
		var pos := rand_pos()
		tree.global_position = pos * 16
		tree.type = randi() % tree.TYPES_SIZE
		if randf() < 0.2:
			tree.face_visible = true
	print(" ---- generated ", amount, " trees")


func gen_board() -> void:
	if forest.current_room % BOARD_INTERVAL != 0:
		return
	var pos := rand_pos() * 16
	_place_board(pos)
	print(" ---- placed quest board at ", pos)


func _place_board(pos: Vector2) -> void:
	var board := preload("res://scenes/rooms/forest/forest_objects/quest_board.tscn").instantiate()
	forest.add_child(board)
	board.global_position = pos
	_init_board(board)


func _init_board(a) -> void:
	const IT := preload("res://scenes/rooms/forest/forest_objects/forest_quest_board.gd")
	var interaction := a.get_node("QuestInteraction") as IT
	interaction.questing = forest.questing
	interaction.level = forest.current_room * 0.1 + 1.0


func gen_bins() -> void:
	var trash_count := roundi(forest.trash_amount_curve.sample_baked(
		forest.current_room / 100.0) * randf()
		+ forest.questing.get_perk_extra_trash_amount())
	for i in trash_count:
		var trash := TRASH.instantiate() as TrashBin
		trash.save = false
		forest.add_child(trash)
		trash.global_position = rand_pos() * 16
		trash.replenish_seconds = -1
		trash.opened.connect(forest.questing.update_quests)
		trash.got_item.connect(forest.questing._trash_item_got)
		bin_loot(trash)
	print(" ---- generated ", trash_count, " bins")


func bin_loot(bin: TrashBin) -> void:
	bin.add_to_group("bins")
	if randf() <= 0.06:
		return
	if randf() <= 0.11:
		bin.full = false
		return
	if randf() <= 0.5:
		# silver
		bin.silver = roundi(forest.current_room * randf_range(1.0, 1.5)
				* (1.0 + forest.questing.get_perk_silver_multiplier()))
		return
	# item
	var values := BIN_LOOT.duplicate()
	var add := forest.questing.get_perk_item_weight_addition_dictionary()
	for k in add.keys():
		values[k] += add[k]
	bin.item = Math.weighted_random(values.keys(), values.values())


func gen_enemies() -> void:
	var enemy_count := clampi(forest.current_room / 12, 1, 12)
	for i in enemy_count:
		var enemy := ENEMY.instantiate()
		enemy.difficulty = forest.current_room * 0.99
		enemy.chase_target = forest.greg
		forest.add_child(enemy)
		var pos := rand_pos().floor()
		enemy.global_position = pos * 16
		enemy.add_to_group("enemies")
	print(" ---- added ", enemy_count, " enemies")


func gen_greenhouse() -> void:
	if not forest.current_room % GREENHOUSE_INTERVAL == 0 or forest.current_room < 2:
		return
	forest.greenhouse = GREENHOUSE.instantiate()
	forest.greenhouse.save = false
	forest.add_child(forest.greenhouse)
	forest.greenhouse.set_vegetables(forest.current_room % VEGET_GREENHOUSE_INTERVAL == 0)
	print(" ---- greenhouse added")


func gen_objects() -> void:
	var weights := ForestObjects.get_db_keys_by_weights()
	var amounts := {}
	var tries := 0
	while generated_objects.size() < OBJECT_AMOUNT and tries < 100:
		tries += 1
		var obkey: StringName = Math.weighted_random(
				weights.keys(), weights.values())
		var object := ForestObjects.get_object(obkey)
		if (
				amounts.get(obkey, 0) >= object.get(ForestObjects.LIMIT, 999)
				or forest.current_room % object.get(
						ForestObjects.EVERY_X_ROOMS, 1) != 0
				or forest.current_room < object.get(
						ForestObjects.MIN_ROOM, 0)
				or forest.current_room > object.get(
						ForestObjects.MAX_ROOM, 19919991)
		):
			continue
		if gen_object(obkey):
			amounts[obkey] = amounts.get(obkey, 0) + 1
	print(" ---- generated ", amounts.values(
			).reduce(func(accum, number): return accum + number, 0), " objects")



func gen_object(type: StringName) -> Node2D:
	var object := ForestObjects.get_object(type)
	var sze: Vector2i = object.get(ForestObjects.SIZE, ForestObjects.DEFAULT_SIZE)
	var start_x := randi_range(-18, 17)
	var start_y := randi_range(-16, 15)
	for i in range(start_x, 17, sze.x):
		for j in range(start_y, 15, sze.y):
			if is_area_free(Rect2i(i, j, sze.x, sze.y)):
				return _place_object(
						# adding half the object's size which makes it
						# not spawn inside obstructed positions
						type, Vector2(i + sze.x * 0.5, j + sze.y * 0.5) * 16)
	return null


func _place_object(type: StringName, position: Vector2) -> Node2D:
	var object := ForestObjects.get_object(type)
	var g: Node2D = object[ForestObjects.SCENE].instantiate()
	g.global_position = position
	# pass in the actual object as the only argument
	if object.get(ForestObjects.FUNCTION, false):
		call(object[ForestObjects.FUNCTION], g)
	forest.add_child(g)
	generated_objects[g.global_position] = type
	return g


func gen_us() -> void:
	var sze := 2
	for i in range(-18, 17, sze):
		for j in range(-16, 15, sze):
			if is_area_free(Rect2i(i, j, sze, sze)):
				var pos := Vector2(
						i,
						j
				)
				var g := preload(
						"res://scenes/characters/overworld/scn_tutorial_guy.tscn"
						).instantiate()
				g.global_position = pos * 16
				g.tutorial_type = g.TutorialType.FOREST
				forest.add_child(g)


func load_from_save() -> void:
	var d := DAT.get_data("forest_save", {}) as Dictionary
	for i in forest.paths.get_layers_count():
		forest.paths.set_layer_enabled(i, false)
	forest.enabled_layer = d.layout
	forest.paths.set_layer_enabled(d.layout, true)
	forest.paths.scale = d.pscale
	for t in d.trees.keys():
		var tree := TREE.instantiate()
		forest.add_child(tree)
		tree.type = d.trees[t]
		tree.global_position = t
	for b in d.bins.keys():
		var bin := TRASH.instantiate()
		forest.add_child(bin)
		bin.global_position = b
		bin.item = d.bins[b].item
		bin.silver = d.bins[b].silver
		bin.full = d.bins[b].full
		bin.save = false
		bin.add_to_group("bins")
		bin.replenish_seconds = -1
		bin.opened.connect(forest.questing.update_quests)
		bin.got_item.connect(forest.questing._trash_item_got)
	for o in d.objects:
		_place_object(d.objects[o], o)
	generated_objects = d.objects
	if d.greenhouse.exists:
		forest.greenhouse = GREENHOUSE.instantiate()
		forest.greenhouse.save = false
		forest.add_child(forest.greenhouse)
		forest.greenhouse.set_vegetables(d.greenhouse.has_vegetables)
	if d.board.exists:
		_place_board(d.board.position)
	forest.current_room = d.room_nr


static func dir_oppos(which: int) -> int:
	if which == NORTH: return SOUTH
	if which == SOUTH: return NORTH
	if which == EAST: return WEST
	if which == WEST: return EAST
	return -1


func _set_flower_sleepy(a) -> void:
	(a as PickableItem).item_type = &"sleepy_flower"
	_delete_item_on_pickup(a)


func _set_fungus_funny(a) -> void:
	(a as PickableItem).item_type = &"funny_fungus"
	_delete_item_on_pickup(a)


func _delete_item_on_pickup(a: PickableItem) -> void:
	a.on_interact.connect(func():
		generated_objects.erase(a.global_position)
	)

