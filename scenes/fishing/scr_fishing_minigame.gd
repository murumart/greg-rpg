extends Node2D

# fishing minigame

const Blocks = preload("res://scenes/fishing/blocks.gd")
const Spawner = preload("res://scenes/fishing/spawner.gd")
const Hook = preload("res://scenes/fishing/hook.gd")

enum States {STOP, MOVE}
var state: States = States.STOP

const SND_CATCH := preload("res://sounds/fishing/catch.ogg")
const SND_CRASH := preload("res://sounds/fishing/crash.ogg")
const SND_HISCR := preload("res://sounds/fishing/highscore.ogg")
const SND_TMOUT := preload("res://sounds/fishing/timeout.ogg")
const SND_CAR := preload("res://sounds/car_overrun.ogg")

const UNIQUE_REWARDS: Array[StringName] = [&"fish", &"rain_boot"]

@onready var blocks: Blocks = $Blocks
@onready var spawner: Spawner = $Spawner

@onready var hook: Hook = $Hook

@onready var fish_parent := $FishParent
@onready var ui := $Ui
@onready var fish_car_label: Label = $Ui/FishCarLabel

@onready var water_layers := $Layers.get_children()

var speed := 60
var depth := 0.0
var points := 0
var fish_caught := 0
var items_caught: Array[StringName] = []
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

@onready var world_environment: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	spawner.hook_data = hook_data
	spawner.fish_car_timer.timeout.connect(_fish_car_timer)
	blocks.fish_spawn_request.connect(spawner._random_spawn)
	blocks.speed = speed

	_set_fancy_grapics_to(bool(not OPT.get_opt("less_fancy_graphics")))

	remove_child(ui)
	SOL.add_ui_child(ui)
	SND.play_song("fishing_game", 1.0, {start_volume = 0, play_from_beginning = true})
	if DAT.get_data("fishing_hook_data", ""):
		hook_data = ResMan.get_item(DAT.get_data("fishing_hook_data")).payload
	hook.set_data(hook_data)
	hook.hit.connect(stop_game)
	hook.speed = speed
	hook.fish_caught.connect(_fish_caught)
	DAT.set_data("fishing_hook_data", "")

	state = States.MOVE
	blocks.state = States.MOVE
	hook.state = States.MOVE


func _physics_process(delta: float) -> void:
	# combo stuff
	recent_fish_caught = maxf(recent_fish_caught - delta
			* pow(2, recent_fish_caught * 0.6)
			* (1.0 / hook_data.combo_time_multiplier), 0.0)
	combo_bar.value = recent_fish_caught
	# depth and time display
	depth_label.text = str("depth: %s m" % roundi(depth * 0.01))
	time_bar.value = time_left
	match state:
		States.MOVE:
			# decorations
			if kiosk_enabled:
				mail_kiosk.position.y -= speed * delta
			if fisherman_enabled:
				fisherman.position.y -= speed * delta
			if shopping_cart_enabled:
				shopping_cart.position.y -= speed * delta
			if cow_ant_enabled:
				cow_ant.position.y -= speed * delta
			depth += delta * speed
			spawner.depth = depth
			update_points_display()
			spawner.background_fish(Vector2(randf_range(-60, 60), 75))
			if randf() < 0.00001  * delta:
				spawner.fish_car_timer.start(0.5)
			if spawner.fish_car_timer.time_left and Engine.get_physics_frames() % 16 == 0:
				SOL.vfx_damage_number(
						fish_car_label.position - SOL.HALF_SCREEN_SIZE
								+ fish_car_label.size * 0.5,
						"fish car!!!",
						Color(1.0, 1.0, 1.0, delta * 16.0)
				)
			if randf() <= 0.002 * delta:
				kiosk_enabled = true
			if randf() <= 0.0002 * delta:
				fisherman_enabled = true
			if randf() <= 0.001 * delta:
				shopping_cart_enabled = true
			if randf() <= 0.000001 * delta:
				cow_ant_enabled = true
			# darker as it gets deeper
			set_water_color(Color("#0054b549").lerp(Color("000e1c49"),
					remap(depth, 0, 3000, 0.0, 1.0)))
			time_left -= maxf(delta * (time_left * 0.54),
					delta * 0.5) * float(bool(fish_caught))
			time_left = minf(time_left, 40.0)
			if time_left <= 0.0:
				SND.play_sound(SND_TMOUT)
				stop_game()


func _fish_caught(node: FishingFish) -> void:
	if not node.item:
		var combo := roundi(recent_fish_caught)
		var pts := roundi((node.value + combo) * hook_data.point_multiplier)
		points += pts
		time_left += (20 + (combo * 20)) * clampf(2000 / depth, 0.1, 1.6)
		update_points_display()
		SOL.vfx("damage_number", node.global_position, {
				"text": str("+", pts),
				"color": Color(1, 1, 1, 0.5) if not combo else
				Color(1.0, 0.8, 0.6, 0.8),
				"speed": 3
			}
		)
		if combo:
			SOL.vfx("damage_number", combo_bar.global_position +
					(Vector2(combo_bar.size.x, 0.0) / 2.0) - SOL.SCREEN_SIZE / 2, {
					"text": "combo! +" + str(combo),
					"color": Color(1.0, 0.8, 0.6, 0.8),
					"speed": 2
				}
			)
		recent_fish_caught += 1.3
		fish_caught += 1
	else:
		items_caught.append(node.item)
		SOL.vfx("damage_number", node.global_position,
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


func stop_game() -> void:
	get_tree().set_group("fishing_fish", "ymoving", false)
	after_crash_timer.start(2)
	state = States.STOP
	blocks.state = States.STOP
	hook.state = States.STOP
	SND.play_song("", 1100.0)


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
	LTS.level_transition(LTS.ROOM_SCENE_PATH % DAT.get_data("current_room", "test_room"))


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
	spawner.spawn_fish_car()
	cars += 1
	if cars > 30 or state == States.STOP:
		spawner.fish_car_timer.stop()
		cars = 0
		if state != States.STOP:
			points += 666
	fish_car_label.visible = spawner.fish_car_timer.time_left > 0
