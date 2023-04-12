extends Node2D

enum States {STOP, MOVE}
var state : States = States.STOP

const FISH_LOAD := preload("res://scenes/fishing/scn_fish.tscn")
const MINE_LOAD := preload("res://scenes/fishing/scn_sea_mine.tscn")

const SND_CATCH := preload("res://sounds/fishing/snd_catch.ogg")
const SND_CRASH := preload("res://sounds/fishing/snd_crash.ogg")
const SND_HISCR := preload("res://sounds/fishing/snd_highscore.ogg")
const SND_TMOUT := preload("res://sounds/fishing/snd_timeout.ogg")

@onready var tilemap := $Blocks
var processed_ypos := 1
@onready var noise : FastNoiseLite = $NoiseSprite.texture.noise
@onready var hook := $Hook
@onready var hook_animator := $Hook/HookAnimator
@onready var line_drawer := $LineDrawer
var hook_positions := [Vector2(0,-60)]
var hook_speed := 80

@onready var fish_parent := $FishParent
@onready var ui := $Ui

@onready var water_layers := $Layers.get_children()

var speed := 60
var depth := 0.0
var points := 0
var fish_caught := 0
var recent_fish_caught := 0.0
var time_left := 80.0
var battle_info : BattleInfo
@onready var depth_label := $Ui/TopContainer/DepthLabel
@onready var points_label := $Ui/TopContainer/PointsLabel
@onready var combo_bar := $Ui/TopContainer/Combobar
@onready var congrats_label := $Ui/Congrats
@onready var after_crash_timer := $Ui/AfterCrashTimer
@onready var time_bar := $Ui/Timebar

@export var depth_fish_increase_curve : Curve

# funny
var kiosk_enabled := false
@onready var mail_kiosk := $FishParent/MailKiosk
var fisherman_enabled := false
@onready var fisherman := $FishParent/Fisherman
var shopping_cart_enabled := false
@onready var shopping_cart := $FishParent/ShoppingCart
var cow_ant_enabled := false
@onready var cow_ant := $FishParent/CowAnt


func _ready() -> void:
	state = States.MOVE
	noise.seed = randi()
	$Hook/HookCollision.body_entered.connect(_on_hook_collision)
	$Hook/HookCollision.area_entered.connect(_on_hook_collision)
	line_drawer.draw.connect(_on_line_draw)
	remove_child(ui)
	SOL.add_ui_child(ui)
	SND.play_song("fishing_game", 1.0, {start_volume = 0, play_from_beginning = true})


func _physics_process(delta: float) -> void:
	recent_fish_caught = maxf(recent_fish_caught - delta * pow(2, recent_fish_caught * 0.6), 0.0)
	combo_bar.value = recent_fish_caught
	depth_label.text = str("depth: %s m" % roundi(depth / 100.0))
	time_bar.value = time_left
	line_movement(delta)
	match state:
		States.MOVE:
			hook_movement(delta)
			tilemap.position.y -= speed * delta
			if kiosk_enabled: mail_kiosk.position.y -= speed * delta
			if fisherman_enabled: fisherman.position.y -= speed * delta
			if shopping_cart_enabled: shopping_cart.position.y -= speed * delta
			if cow_ant_enabled: cow_ant.position.y -= speed * delta
			noise.offset.y += (speed * delta) / 16.0
			depth += delta * speed
			process_tilemap()
			set_water_color(Color("#0054b549").lerp(Color("000e1c49"), remap(depth, 0, 30000, 0.0, 1.0)))
			time_left -= maxf(delta * (time_left * 0.66), delta * 0.5) * float(bool(fish_caught))
			time_left = minf(time_left, 40.0)
			if time_left <= 0.0:
				SND.play_sound(SND_TMOUT)
				stop_game()


func hook_movement(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	hook.global_position += input * hook_speed * 1 * delta
	hook.global_position.y = clampf(hook.global_position.y, -60, 60)
	$Hook/Look.rotation_degrees = move_toward($Hook/Look.rotation_degrees, input.x * 30, hook_speed * delta * (2 * int(not bool(input.x) or signf($Hook/Look.rotation_degrees) != signf(input.x))) + 1)
	if Engine.get_physics_frames() % 4 == 0:
		hook_positions.append(hook.global_position)


func line_movement(delta : float) -> void:
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
	if state == States.STOP: return
	if node is TileMap or node.get_parent().get("hazardous"):
		#get_tree().reload_current_scene()
		if node.get_parent().has_method("caught"):
			node.get_parent().call("caught")
			hook.hide()
		SND.play_sound(SND_CRASH)
		SOL.shake(0.4)
		wiggle.call()
		stop_game()
	elif node is Area2D and node.get_parent() is FishingFish:
		node = node.get_parent() as FishingFish
		if node.moving and not node.decor:
			var combo := roundi(recent_fish_caught)
			points += node.value + combo
			time_left += (20 + (combo * 20)) * clampf(2000 / depth, 0.1, 1.6)
			points_label.text = str("points: ", points)
			SOL.vfx(
				"damage_number",
				node.global_position,
				{
					"text": str("+", node.value + combo),
					"color": Color(1, 1, 1, 0.5) if not combo else
					Color(1.0, 0.8, 0.6, 0.8),
					"speed": 3
				}
			)
			if combo:
				SOL.vfx(
					"damage_number",
					combo_bar.global_position + (Vector2(combo_bar.size.x, 0.0) / 2.0) - SOL.SCREEN_SIZE / 2,
					{
						"text": str("combo! +", combo),
						"color": Color(1.0, 0.8, 0.6, 0.8),
						"speed": 2
					}
				)
			node.caught()
			recent_fish_caught += 1.3
			fish_caught += 1
			SND.play_sound(SND_CATCH, {"pitch": remap(node.value, 1, 11, 1.0, 0.66)})
			SND.play_sound(preload("res://sounds/spirit/snd_fish_attack.ogg"), {pitch = randf_range(0.9, 1.4)})
			wiggle.call()


func stop_game() -> void:
	get_tree().set_group("fishing_fish", "ymoving", false)
	after_crash_timer.start(2)
	state = States.STOP
	SND.play_song("", 1100.0)


func _on_line_draw() -> void:
	for i in hook_positions.size():
		var pos : Vector2 = hook_positions[i]
		line_drawer.draw_line(
			Vector2(0, -99) if i <= 0 else hook_positions[i - 1],
			pos if i < hook_positions.size() - 1 else hook.global_position,
			Color.BLACK,
			1.0
		)


func process_tilemap() -> void:
	var ypos := roundi(tilemap.position.y / 16.0)
	if ypos == processed_ypos: return
	var path_noise_value := roundi((remap(noise.get_noise_1d(tilemap.position.y / 8000.0), -1, 1, -6, 6) + remap(noise.get_noise_1d((tilemap.position.y + 1) / 8000.0), -1, 1, -6, 6)) / 2.0)
	
	delete_offscreen_tiles(ypos)
	
	var rock_array := []
	for x in 12:
		var cell := Vector2i(x - 6, -ypos + 5)
		var noise_value := noise.get_noise_2d(x, 10)
		if (
				!(noise_value > -0.2 and noise_value < 0.2) and 
				!(absi(cell.x - path_noise_value) <= 2) and 
				randf() <= 0.95
			) or (
				cell.x <= -5 or cell.x >= 4
			): rock_array.append(cell)
	
	var bg_rock_array := []
	for x in 12:
		var cell := Vector2i(x - 6, -ypos + 5)
		var noise_value := noise.get_noise_2d(x + 384, 10)
		if (noise_value > 0 and randf() <= 0.95) or (cell.x <= -5 or cell.x >= 4):
			bg_rock_array.append(cell)
	
	tilemap.set_cells_terrain_connect(1, rock_array, 0, 0)
	tilemap.set_cells_terrain_connect(0, bg_rock_array, 0, 1)
	
	for x in 12:
		var cell := Vector2i(x - 6, -ypos + 4)
		if not tilemap.get_cell_tile_data(1, cell):
			if randf() < depth_fish_increase_curve.sample(depth / 20_000.0) / 2.0: spawn_fish(tilemap.to_global(tilemap.map_to_local(cell)))
			if depth >= 7500:
				if randf() < depth_fish_increase_curve.sample(depth / 20_000.0) / 16.0: spawn_mine(tilemap.to_global(tilemap.map_to_local(cell)))
		if randf() < depth_fish_increase_curve.sample(depth / 20_000.0): spawn_fish(tilemap.to_global(tilemap.map_to_local(cell)), true)
	
	if randf() <= 0.002: kiosk_enabled = true
	if randf() <= 0.0002: fisherman_enabled = true
	if randf() <= 0.001: shopping_cart_enabled = true
	if randf() <= 0.00001: cow_ant_enabled = true
	
	processed_ypos = ypos


func spawn_fish(coords : Vector2, background := false) -> void:
	var fish := FISH_LOAD.instantiate()
	fish.global_position = coords
	fish.depth = roundi(depth / 100.0)
	if background:
		fish.z_index = -8
		fish.decor = true
		var fishsc := randf_range(0.2, 0.8)
		fish.scale = Vector2(fishsc, fishsc)
		fish.yspeed = roundi(randf_range(40 * fishsc, 60 * fishsc))
		fish.modulate = Color(0.8, 0.9, 1.0, 0.8 * fishsc)
	fish_parent.add_child(fish)


func spawn_mine(coords: Vector2, background := false) -> void:
	var mine := MINE_LOAD.instantiate()
	mine.global_position = coords
	mine.depth = roundi(depth / 100.0)
	if background:
		mine.z_index = -8
		mine.decor = true
		var fishsc := randf_range(0.2, 0.8)
		mine.scale = Vector2(fishsc, fishsc)
		mine.yspeed = roundi(randf_range(40 * fishsc, 60 * fishsc))
		mine.modulate = Color(0.8, 0.9, 1.0, 0.8 * fishsc)
	fish_parent.add_child(mine)


func delete_offscreen_tiles(ypos: int) -> void:
	for x in 12:
		var cell := Vector2i(x - 6, -ypos - 6)
		tilemap.erase_cell(0, cell)
		tilemap.erase_cell(1, cell)


func _on_after_crash_timer_timeout() -> void:
	var score := roundi(depth / 100.0) + points
	var high_score : bool = score > DAT.get_data("fishing_high_score", 0)
	if high_score:
		DAT.set_data("fishing_high_score", score)
	if battle_info:
		LTS.enter_battle(battle_info)
		return
	
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
	
	rewards.rewards.append(srew)
	rewards.rewards.append(xrew)
	if high_score:
		var hsrew := Reward.new()
		hsrew.type = BattleRewards.Types.SILVER
		hsrew.property = "2"
		rewards.rewards.append(hsrew)
	SND.play_sound(SND_HISCR if high_score else preload("res://sounds/snd_misc_click.ogg"))
	
	congrats_label.text = str("[center]", high_score_text if high_score else "", "\n", good_job_text if score > 9 else bad_job_text, "\n", "score: ", score)
	rewards.granted.connect(func():
		SOL.dialogue_closed.connect(self.end, CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT)
	rewards.grant()


func end() -> void:
	LTS.gate_id = LTS.GATE_EXIT_FISHING
	LTS.level_transition(LTS.ROOM_SCENE_PATH % DAT.get_data("current_room", "test_room"))


func set_water_color(to: Color) -> void:
	for x in water_layers:
		var layer := x as ColorRect
		layer.color = to
