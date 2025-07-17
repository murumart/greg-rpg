extends Node2D

const FG := preload("res://scenes/fishing/scr_fishing_minigame.gd")

const FISH_LOAD := preload("res://scenes/fishing/scn_fish.tscn")
const MINE_LOAD := preload("res://scenes/fishing/scn_sea_mine.tscn")
const CAR_LOAD := preload("res://scenes/fishing/scn_fish_car.tscn")

const DEPMUL = 5e-05

@export var depth_fish_increase_curve: Curve
@export var depth_item_increase_curve: Curve
@export var random_items: WeightedRandomContainer
@export var fish_parent: Node2D
@onready var fish_car_timer: Timer = $FishCarTimer

var hook_data := BattlePayloadFishing.new()
var depth: float
var items_spawned: Array[StringName] = []


func _random_spawn(pos: Vector2) -> void:
	var df_sample := depth_fish_increase_curve.sample(depth * DEPMUL)
	var r := randf()
	var sspawn := r < df_sample * 0.5
	#print("SPAWN: ", df_sample * 0.5 * 1000, " r: ", r, " ss: ", sspawn)
	if sspawn:
		spawn_fish(pos)
	elif depth >= 7500:
		if (randf() < df_sample * 0.0625 * 1000):
			spawn_mine(pos)
	if (randf() < depth_item_increase_curve.sample(depth * DEPMUL) * 0.00285714):
		spawn_item(random_items.get_random_id(), pos)


func background_fish(pos: Vector2) -> void:
	var df_sample := depth_fish_increase_curve.sample(depth * DEPMUL)
	if randf() < df_sample:
		spawn_fish(pos, true)


func spawn_swimmer(node: FishingFish, coords: Vector2, background := false) -> void:
	node.global_position = coords
	node.depth = roundi(depth / 100.0)
	# background node for decoration
	if background:
		node.z_index = -8
		node.decor = true
		var fishsc := randf_range(0.2, 0.8)
		node.scale = Vector2(fishsc, fishsc)
		node.yspeed = roundi(randf_range(40 * fishsc, 60 * fishsc))
		node.modulate = Color(0.8, 0.9, 1.0, 0.8 * fishsc)
	fish_parent.add_child(node)
	node.hook_area_collision.scale *= hook_data.fish_hitbox_size_multiplier
	if background:
		node.wallrun_area.queue_free()
		node.hook_area.queue_free()


func spawn_fish(coords: Vector2, background := false) -> void:
	var fish := FISH_LOAD.instantiate()
	spawn_swimmer(fish, coords, background)


# sea mines that you can run into to lose
func spawn_mine(coords: Vector2, background := false) -> void:
	var mine := MINE_LOAD.instantiate()
	spawn_swimmer(mine, coords, background)


func spawn_item(item_id: StringName, coords: Vector2) -> void:
	var rew_s := str(Reward.new(
			{"property": item_id, "type": BattleRewards.Types.ITEM}))
	if not rew_s in DAT.get_data("unique_rewards", []) and not (
		(item_id in FG.UNIQUE_REWARDS) and (item_id in items_spawned)
	):
		var item := FISH_LOAD.instantiate()
		if not item_id in items_spawned:
			items_spawned.append(item_id)
		item.item = item_id
		item.is_fish = false
		spawn_swimmer(item, coords, false)


func spawn_fish_car() -> void:
	var player := $FishCarTimer/AudioStreamPlayer2D
	var dir_left := true if randf() < 0.5 else false
	var spawn_pos := Vector2(
			87 if dir_left else -87,
			randf_range(-30, 80)
	)
	var instance := CAR_LOAD.instantiate()
	instance.direction = int(not dir_left)
	spawn_swimmer(instance, spawn_pos, false)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(instance, "speed", 90.0, 0.6).from(10.0)
	player.global_position = spawn_pos
	player.stop()
	player.play()
