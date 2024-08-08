extends Node2D

# fishing minigame

enum States {STOP, MOVE}
var state: States = States.STOP

const FISH_LOAD := preload("res://scenes/fishing/scn_fish.tscn")
const MINE_LOAD := preload("res://scenes/fishing/scn_sea_mine.tscn")
const CAR_LOAD := preload("res://scenes/fishing/scn_fish_car.tscn")

const SND_CATCH := preload("res://sounds/fishing/catch.ogg")
const SND_CRASH := preload("res://sounds/fishing/crash.ogg")
const SND_HISCR := preload("res://sounds/fishing/highscore.ogg")
const SND_TMOUT := preload("res://sounds/fishing/timeout.ogg")
const SND_CAR := preload("res://sounds/car_overrun.ogg")

const UNIQUE_REWARDS: Array[StringName] = [&"fish", &"rain_boot"]

@onready var tilemap := $Blocks as TileMap
var processed_ypos := 1
@onready var noise: FastNoiseLite = $NoiseSprite.texture.noise
@onready var hook := $Hook
@onready var hook_sprite_main: Sprite2D = $Hook/Look
@onready var hook_sprite_sub: Sprite2D = $Hook/Look/Look2
@onready var hook_animator := $Hook/HookAnimator
@onready var line_drawer := $LineDrawer
var hook_positions := [Vector2(0,-60)]
var hook_speed := 80

@onready var fish_parent := $FishParent
@onready var ui := $Ui
@onready var fish_car_label: Label = $Ui/FishCarLabel

@onready var water_layers := $Layers.get_children()

var speed := 60
var depth := 0.0
var points := 0
var fish_caught := 0
var items_caught: Array[StringName] = []
var items_spawned: Array[StringName] = []
var recent_fish_caught := 0.0
var time_left := 80.0
var battle_info: BattleInfo
@onready var depth_label := $Ui/TopContainer/DepthLabel
@onready var points_label := $Ui/TopContainer/PointsLabel
@onready var combo_bar := $Ui/TopContainer/Combobar
@onready var congrats_label := $Ui/Congrats
@onready var after_crash_timer := $Ui/AfterCrashTimer
@onready var time_bar := $Ui/Timebar

@export var depth_fish_increase_curve: Curve
@export var depth_item_increase_curve: Curve
@export var random_items: WeightedRandomContainer

var hook_data := BattlePayloadFishing.new()

# funny
var kiosk_enabled := false
@onready var mail_kiosk := $FishParent/MailKiosk
var fisherman_enabled := false
@onready var fisherman := $FishParent/Fisherman
var shopping_cart_enabled := false
@onready var shopping_cart := $FishParent/ShoppingCart
var cow_ant_enabled := false
@onready var cow_ant := $FishParent/CowAnt

@onready var fish_car_timer: Timer = $FishCarTimer

@onready var world_environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	_set_fancy_grapics_to(bool(not OPT.get_opt("less_fancy_graphics")))
	$Hook/HookCollision/CollisionShape2D.shape.size = Vector2(2, 3
			) * hook_data.world_hitbox_size_multiplier
	fish_car_timer.timeout.connect(_fish_car_timer)
	state = States.MOVE
	noise.seed = randi()
	$Hook/HookCollision.body_entered.connect(_on_hook_collision)
	$Hook/HookCollision.area_entered.connect(_on_hook_collision)
	line_drawer.draw.connect(_on_line_draw)
	remove_child(ui)
	SOL.add_ui_child(ui)
	SND.play_song("fishing_game", 1.0, {start_volume = 0, play_from_beginning = true})
	if DAT.get_data("fishing_hook_data", ""):
		hook_data = ResMan.get_item(DAT.get_data("fishing_hook_data")).payload
		hook_sprite_main.texture = ResMan.get_item(hook_data.item_id).texture
		hook_sprite_sub.texture = ResMan.get_item(hook_data.item_id).texture
	DAT.set_data("fishing_hook_data", "")


func _physics_process(delta: float) -> void:
	# combo stuff
	recent_fish_caught = maxf(recent_fish_caught - delta
			* pow(2, recent_fish_caught * 0.6)
			* (1.0 / hook_data.combo_time_multiplier), 0.0)
	combo_bar.value = recent_fish_caught
	# depth and time display
	depth_label.text = str("depth: %s m" % roundi(depth * 0.01))
	time_bar.value = time_left
	line_movement(delta)
	match state:
		States.MOVE:
			hook_movement(delta)
			# world moves to give illusion of going deeper
			tilemap.position.y -= speed * delta
			# decorations
			if kiosk_enabled:
				mail_kiosk.position.y -= speed * delta
			if fisherman_enabled:
				fisherman.position.y -= speed * delta
			if shopping_cart_enabled:
				shopping_cart.position.y -= speed * delta
			if cow_ant_enabled:
				cow_ant.position.y -= speed * delta
			noise.offset.y += (speed * delta) / 16.0
			depth += delta * speed
			process_tilemap()
			# darker as it gets deeper
			set_water_color(Color("#0054b549").lerp(Color("000e1c49"),
					remap(depth, 0, 3000, 0.0, 1.0)))
			time_left -= maxf(delta * (time_left * 0.55),
					delta * 0.5) * float(bool(fish_caught))
			time_left = minf(time_left, 40.0)
			if time_left <= 0.0:
				SND.play_sound(SND_TMOUT)
				stop_game()
	if fish_car_timer.time_left and Engine.get_physics_frames() % 16 == 0:
		SOL.vfx_damage_number(
				fish_car_label.position - SOL.HALF_SCREEN_SIZE
						+ fish_car_label.size * 0.5,
				"fish car!!!",
				Color(1.0, 1.0, 1.0, delta * 16.0)
		)


func hook_movement(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var movement := input * hook_speed * delta
	movement.x *= hook_data.horizontal_movement_speed_multiplier
	movement.y *= hook_data.vertical_movement_speed_multiplier
	hook.global_position += movement
	hook.global_position.y = clampf(hook.global_position.y, -60, 50)
	# swaying left-right
	$Hook/Look.rotation_degrees = move_toward($Hook/Look.rotation_degrees, input.x * 30, hook_speed * delta * (2 * int(not bool(input.x) or signf($Hook/Look.rotation_degrees) != signf(input.x))) + 1)
	if Engine.get_physics_frames() % 4 == 0:
		hook_positions.append(hook.global_position)


func line_movement(delta: float) -> void:
	# slowly sway as the water moves
	for pos in hook_positions:
		var i := hook_positions.find(pos)
		pos.y -= (speed * delta * randf_range(0.8, 1.2)) if state == States.MOVE else 0.0
		pos.x = move_toward(pos.x, hook.global_position.x, delta * randf_range(2, 4))
		if pos.y < -66:
			hook_positions.remove_at(i)
		else:
			hook_positions[i] = pos
	line_drawer.queue_redraw()


func _on_hook_collision(node: Node2D) -> void:
	var wiggle := func():
		hook_animator.advance(0)
		hook_animator.play("hit")
		SOL.shake(0.2)
	if state == States.STOP:
		return
	# hitting an obstacle
	if node is TileMap or node.get_parent().get("hazardous"):
		#get_tree().reload_current_scene()
		if node.get_parent().has_method("caught"):
			node.get_parent().call("caught")
			hook.hide()
		SND.play_sound(SND_CRASH)
		SOL.shake(0.4)
		wiggle.call()
		stop_game()
	# hitting a nice fish
	elif node is Area2D and node.get_parent() is FishingFish:
		node = node.get_parent() as FishingFish
		if node.moving and not node.decor:
			if not node.item:
				var combo := roundi(recent_fish_caught)
				var pts := roundi(node.value + combo) * hook_data.point_multiplier
				points += pts
				time_left += (20 + (combo * 20)) * clampf(2000 / depth, 0.1, 1.6)
				update_points_display()
				SOL.vfx(
					"damage_number",
					node.global_position,
					{
						"text": str("+", pts),
						"color": Color(1, 1, 1, 0.5) if not combo else
						Color(1.0, 0.8, 0.6, 0.8),
						"speed": 3
					}
				)
				if combo:
					SOL.vfx(
						"damage_number",
						combo_bar.global_position +
							(Vector2(combo_bar.size.x, 0.0) / 2.0) - SOL.SCREEN_SIZE / 2,
						{
							"text": "combo! +" + str(combo),
							"color": Color(1.0, 0.8, 0.6, 0.8),
							"speed": 2
						}
					)
				recent_fish_caught += 1.3
				fish_caught += 1
			else:
				items_caught.append(node.item)
				SOL.vfx(
					"damage_number",
					node.global_position,
					{
						"text": ResMan.get_item(node.item).name,
						"color": Color(0.3, 1, 0.4, 0.5),
						"speed": 0.75
					}
				)
			node.caught()
			SND.play_sound(SND_CATCH, {"pitch_scale": remap(node.value, 1, 11, 1.0, 0.66)})
			SND.play_sound(preload("res://sounds/spirit/fish_attack.ogg"),
					{pitch_scale = randf_range(0.9, 1.4)})
			wiggle.call()


func stop_game() -> void:
	get_tree().set_group("fishing_fish", "ymoving", false)
	after_crash_timer.start(2)
	state = States.STOP
	SND.play_song("", 1100.0)


func _on_line_draw() -> void:
	for i in hook_positions.size():
		var pos: Vector2 = hook_positions[i]
		line_drawer.draw_line(
			Vector2(0, -99) if i <= 0 else hook_positions[i - 1],
			pos if i < hook_positions.size() - 1 else hook.global_position,
			Color.BLACK,
			1.0
		)


func process_tilemap() -> void:
	# the tilemap actually continuously
	var ypos := roundi(tilemap.position.y * 0.0625)
	if ypos == processed_ypos:
		return
	update_points_display()
	var path_noise_value := roundi((remap(
			noise.get_noise_1d(tilemap.position.y * 0.000125), -1, 1, -6, 6)
			+ remap(noise.get_noise_1d((tilemap.position.y + 1) * 0.000125),
			-1, 1, -6, 6)) * 0.5)

	# this might optimise things. i hope
	delete_offscreen_tiles(ypos)

	var rock_array := []
	# tilemap width is 12
	for x in 12:
		var cell := Vector2i(x - 6, -ypos + 5)
		var noise_value := noise.get_noise_2d(x, 10)
		# random caves
		if (
			not (noise_value > -0.2 and noise_value < 0.2) and
			not (absi(cell.x - path_noise_value) <= 2) and
			randf() <= 0.95
		) or (
			cell.x <= -5 or cell.x >= 4
		):
			rock_array.append(cell)
		else: #spawn fish
			if randf() < depth_fish_increase_curve.sample(depth * 5e-05) * 0.5:
				spawn_fish(tilemap.to_global(tilemap.map_to_local(cell)))
			if depth >= 7500:
				if (randf() < depth_fish_increase_curve.sample(depth * 5e-05)
						* 0.0625):
					spawn_mine(tilemap.to_global(tilemap.map_to_local(cell)))
			if (randf() < depth_item_increase_curve.sample(depth * 5e-05)
					* 0.00285714):
				spawn_item(
						random_items.get_random_id(),
						tilemap.to_global(tilemap.map_to_local(cell)))
		# background fish
		if randf() < depth_fish_increase_curve.sample(depth * 5e-05):
			spawn_fish(tilemap.to_global(tilemap.map_to_local(cell)), true)
	# background
	var bg_rock_array := []
	for x in 12:
		var cell := Vector2i(x - 6, -ypos + 5)
		var noise_value := noise.get_noise_2d(x + 384, 10)
		if (noise_value > 0 and randf() <= 0.95) or (cell.x <= -5 or cell.x >= 4):
			bg_rock_array.append(cell)

	_set_cells(rock_array, bg_rock_array)

	# decorations random
	if randf() <= 0.002:
		kiosk_enabled = true
	if randf() <= 0.0002:
		fisherman_enabled = true
	if randf() <= 0.001:
		shopping_cart_enabled = true
	if randf() <= 0.00001:
		cow_ant_enabled = true

	processed_ypos = ypos
	if randf() < 0.0001:
		fish_car_timer.start(0.5)


# the most process intensive part of process_tilemap
func _set_cells(rock_array: Array, bg_rock_array: Array) -> void:
	if world_environment.environment:
		tilemap.set_cells_terrain_connect(1, rock_array, 0, 0)
		tilemap.set_cells_terrain_connect(0, bg_rock_array, 0, 1)
		return
	# lower graphics
	for pos in rock_array:
		tilemap.set_cell(1, pos, 0, Vector2i(13, 16))
	for pos in bg_rock_array:
		tilemap.set_cell(0, pos, 1, Vector2i(13, 16))


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
		(item_id in UNIQUE_REWARDS) and (item_id in items_spawned)
	):
		var item := FISH_LOAD.instantiate()
		if not item_id in items_spawned:
			items_spawned.append(item_id)
		item.item = item_id
		item.is_fish = false
		spawn_swimmer(item, coords, false)


func delete_offscreen_tiles(ypos: int) -> void:
	for x in 12:
		var cell := Vector2i(x - 6, -ypos - 6)
		tilemap.erase_cell(0, cell)
		tilemap.erase_cell(1, cell)


# game ends here
func _on_after_crash_timer_timeout() -> void:
	var score := roundi(depth * 0.01) + points
	var high_score: bool = score > DAT.get_data("fishing_high_score", 0)
	DAT.incri("fishings_finished", 1)
	DAT.incri("fish_caught", fish_caught)
	if DAT.get_data("fishing_max_depth", 0) < depth:
		DAT.set_data("fishing_max_depth", depth)
	if high_score:
		DAT.set_data("fishing_high_score", score)
	if battle_info:
		LTS.enter_battle(battle_info)
		return

	# setting rewards
	var rewards := BattleRewards.new()

	var bad_job_text := "you tried!"
	var good_job_text := "good job!"
	var high_score_text := "[color=#88ff00]high score![/color]"

	var srew := Reward.new()
	srew.type = BattleRewards.Types.SILVER
	srew.property = str(roundi(score * 0.19))

	var xrew := Reward.new()
	xrew.type = BattleRewards.Types.EXP
	xrew.property = str(roundi(score * 0.088))

	rewards.add(srew)
	rewards.add(xrew)
	if high_score:
		var hsrew := Reward.new()
		hsrew.type = BattleRewards.Types.SILVER
		hsrew.property = str(roundi(score * 0.02))
		rewards.add(hsrew)

	for item in items_caught:
		var rew := Reward.new()
		rew.type = BattleRewards.Types.ITEM
		rew.property = str(item)
		rew.unique = item in UNIQUE_REWARDS
		rewards.add(rew)

	# granting rewards
	SND.play_sound(SND_HISCR if high_score
			else preload("res://sounds/misc_click.ogg"))
	congrats_label.text = str(
			"[center]", high_score_text if high_score else "",
			"\n", good_job_text if score > 9 else bad_job_text, "\n",
			"score: ", score)
	rewards.granted.connect(func():
		SOL.dialogue_closed.connect(self.end, CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT)
	rewards.grant()


func end() -> void:
	LTS.gate_id = LTS.GATE_EXIT_FISHING
	LTS.level_transition(LTS.ROOM_SCENE_PATH
			% DAT.get_data("current_room", "test_room"))


func set_water_color(to: Color) -> void:
	for x in water_layers:
		var layer := x as ColorRect
		layer.color = to


func update_points_display() -> void:
	points_label.text = str("points: ", roundi(depth / 100.0) + points)


var envir: Environment
func _set_fancy_grapics_to(fancy: bool) -> void:
	if fancy:
		if envir:
			world_environment.environment = envir
		return
	envir = world_environment.environment
	world_environment.set_environment(null)


var cars := 0
func _fish_car_timer() -> void:
	_spawn_fish_car()
	cars += 1
	if cars > 30 or state == States.STOP:
		fish_car_timer.stop()
		cars = 0
		if state != States.STOP:
			points += 666
	fish_car_label.visible = fish_car_timer.time_left > 0


func _spawn_fish_car() -> void:
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
