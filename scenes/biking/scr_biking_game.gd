class_name BikingGame extends Node2D

# biking minigame

const BikingGreg := preload("res://scenes/biking/scr_biking_greg.gd")
const ROAD_BOUNDARIES := Rect2(Vector2(2, 116), Vector2(158, 72))

const ROAD_LENGTH := 800.0
const MAIL_KIOSK_INTERVAL := 200
const KIOSK_BUFFER := 10

const HELL_COLOUR := Color(0.96074420213699, 0.62273794412613, 0.68452841043472)

@onready var background_sky := $Background/Sky
@onready var background_trees := $Background/Trees
@onready var background_town := $Background/Town
@onready var background_field := $Background/Field
@onready var background_snail_hell := $Background/SnailHellBackground
@onready var colour_changer: CanvasModulate = $Background/ColourChanger

@onready var debug := $UI/debug

@onready var road := $Road
var speed := 60

var speed_before_inv := 0
var speed_before_snail := 0

var snails_until_hell := 10
var snails_to_escape_hell := 120

@onready var bike: BikingGreg = $Bike

@onready var ui := $UI

@onready var obstacle_timer := $ObstacleTimer
@onready var coin_timer := $CoinTimer
@onready var snail_timer := $SnailTimer
@onready var mailbox_timer := $MailboxTimer
@onready var punishment_timer := $PunishmentTimer
const OBSTACLE_PACKED: Array[PackedScene] = [
	preload("res://scenes/biking/moving_objects/scn_obstacle_pothole.tscn"),
	preload("res://scenes/biking/moving_objects/scn_obstacle_log.tscn"),
]
const MAIL_BOX_LOAD := preload("res://scenes/biking/moving_objects/scn_biking_mailbox.tscn")
const COIN_LOAD := preload("res://scenes/biking/moving_objects/scn_biking_coin.tscn")
const SNAIL_LOAD := preload("res://scenes/biking/moving_objects/scn_biking_snail.tscn")
const HOUSE_LOAD := preload("res://scenes/biking/moving_objects/scn_biking_house.tscn")

var distance := 0.0
var stop_meter := -1.0
var kiosk_activated := false:
	set(to):
		kiosk_activated = to
var current_kiosk: BikingMovingObject
var kiosks_activated := 0

var inventory := []

var mail_hits := 0
var silver_collected := 0
var snails_hit := 0
var current_perk := "": set = _set_perk
var currently_hell := false
var hell_time := 0
var hells_survived := 0


func _ready() -> void:
	DAT.set_data("biking_game_played", true)
	bike.died.connect(_on_died)
	obstacle_timer.start()
	coin_timer.start()
	snail_timer.start()
	mailbox_timer.start()
	set_speed(speed)
	remove_child(ui)
	SOL.add_ui_child(ui)
	ui.health_bar.max_value = bike.max_health
	bike.health_changed.connect(ui.display_health)
	ui.display_health(bike.health)
	DAT.set_data("last_kiosk_open_second", DAT.seconds)
	SND.play_song("mail_mission", 1.0, {"play_from_beginning": true})
	DAT.death_reason = ""
	update_ui()


func _physics_process(delta: float) -> void:
	# road moves backward - illusion of forward movement
	road.global_position.x = wrapf(road.global_position.x - (speed * delta), -16, 32)
	distance += speed * delta * int(not currently_hell)
	ui.set_pointer_pos(get_meter() / ROAD_LENGTH)

	# the kiosk appears every INTERVAL "meters"
	if (roundi(get_meter() + KIOSK_BUFFER) % MAIL_KIOSK_INTERVAL) == 0:
		current_perk = ""
		if currently_syrup: stop_syrup()
		set_speed(60)
		bike.mail_mode = bike.MailModes.NORMAL
		the_kiosk()

	# at the end of the road, do some testing and fixing if necess
	if roundi(get_meter()) >= ROAD_LENGTH - 1:
		if currently_syrup: stop_syrup()
		set_speed(0)
		check_if_kiosk_has_made_it()

	if Input.is_action_just_pressed("menu") and !ui.inventory_open:
		open_inventory()

	if (Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("menu")) and ui.inventory_open:
		close_inventory()

	# parallax background
	background_trees.region_rect.position.x = wrapf(background_trees.region_rect.position.x + speed * delta * 0.22, 0.0, background_trees.region_rect.size.x * 2.0)
	background_town.region_rect.position.x = wrapf(background_town.region_rect.position.x + speed * delta * 0.33, 0.0, background_town.region_rect.size.x)
	background_field.region_rect.position.x = wrapf(background_field.region_rect.position.x + speed * delta * 0.77, 0.0, background_field.region_rect.size.x * 2.0)

	# DEBUG (rememmber to remove)
	if not DIR.standalone():
		if Input.is_action_pressed("ui_page_down"):
			distance += 60
		if Input.is_action_just_pressed("ui_end"):
			while not (roundi(get_meter() + KIOSK_BUFFER) % MAIL_KIOSK_INTERVAL) == 0:
				distance += 1

	if currently_syrup and get_meter() >= syrup_stop_meter:
		stop_syrup()

#	debug.text = "dist: %s
#meter: %s
#perc: %s" % [distance, roundf(get_meter()), snappedf(get_meter() / ROAD_LENGTH, 0.01)]


func set_speed(to: int) -> void:
	speed = to
	get_tree().set_group("speedsters", "speed", speed)
	$Bike/RoadCollision.constant_linear_velocity.x = - speed


func _on_died() -> void:
	# setting the death reason only if it hasn't been set already
	if not DAT.death_reason.length():
		DAT.death_reason = "bikecry" if randf() <= 0.95 else "mail_disappointment"
	set_speed(0)
	if currently_hell:
		# funny
		for s in get_tree().get_nodes_in_group("biking_snails"):
			var tw := create_tween()
			tw.tween_property(s, "global_position", bike.global_position + Vector2(
				randf_range(-4.0, 4.0),
				randf_range(-4.0, 4.0)
			), 2.0)
	await get_tree().create_timer(2.0).timeout
	LTS.to_game_over_screen()


# spawning obstacles
func _on_obstacle_timer_timeout() -> void:
	if speed < 5: return # don't while stopped
	if kiosk_activated: return
	# obstacle
	obstacle_timer.start(randfn(1.5, 1.5) * 1.0 if not currently_hell else 0.75)
	var obstacle: BikingObstacle = OBSTACLE_PACKED.pick_random().instantiate()
	obstacle.speed = speed
	obstacle.randomise_position()
	add_child(obstacle)
	if obstacle.name.contains("Log"):
		obstacle.rotation = randf_range(-TAU, TAU)
		if current_perk == "less_logs" and randf() <= 0.95:
			obstacle.queue_free()
	if obstacle.name.contains("Pothole"):
		if current_perk == "nicer_roads" and randf() <= 0.95:
			obstacle.queue_free()
	if currently_hell and randf() <= 0.25:
		var beam_target: BikingObstacle = preload("res://scenes/biking/moving_objects/scn_sky_target.tscn").instantiate()
		beam_target.randomise_position()
		beam_target.position.x += randfn(20, 20) + 20
		beam_target.speed = speed
		add_child(beam_target)
		for node in get_tree().get_nodes_in_group("biking_obstacles"):
			if node == beam_target:
				continue
			if node.global_position.distance_to(beam_target.global_position) < 10:
				beam_target.queue_free()
				break


func _on_coin_timer_timeout() -> void:
	if speed < 5: return
	if currently_hell: return
	if kiosk_activated: return
	coin_timer.start(randfn(2, 2))
	for i in 1 + (int(current_perk == "fast_earner") * randi_range(3, 6)):
		if randf() <= 0.55:
			spawn_coin()
			if randf() <= 0.44:
				spawn_coin()
				if randf() <= 0.33:
					spawn_coin()


func _on_snail_timer_timeout() -> void:
	if speed < 5:
		return
	if kiosk_activated:
		return
	snail_timer.start(randf_range(2, 5) * 0.1 if currently_hell else 1.0)
	spawn_snail()


var mails_wo_box := 0

func _on_mailbox_timer_timeout() -> void:
	if speed < 5:
		return
	mailbox_timer.start(0.5)
	mails_wo_box += 1
	if randf() <= 0.89:
		var house := HOUSE_LOAD.instantiate()
		house.speed_scale = randf_range(0.55, 0.77)
		var x: float = remap(house.speed_scale, 0.5, 1.0, 0.1, 1.0)
		house.modulate = Color(x, x, x)
		house.z_index = roundi(remap(house.speed_scale, 0.5, 1.0, -14, -11))
		add_child(house)
		house.global_position.x = randi_range(200, 248)
		house.global_position.y = randi_range(44, 48)
		if currently_hell:
			house.set_snail(true)
		if randf() < 0.1:
			house.z_index = -10
			house.scale = Vector2(2, 2)
			house.speed_scale = 0.96
			house.global_position.y += 5
			house.global_position.x += randf_range(30, 40)
			house.modulate = Color.WHITE
		elif randf() < 0.4:
			house.z_index = -16
			house.scale = Vector2(0.5, 0.5)
			house.speed_scale *= 0.5
			house.modulate = house.modulate.darkened(0.3)
	if kiosk_activated:
		return
	if currently_hell:
		return
	if randf() <= 0.11 or mails_wo_box > 5:
		mails_wo_box = 0
		var mailbox: BikingMovingObject = MAIL_BOX_LOAD.instantiate()
		mailbox.global_position = Vector2(176, 68)
		mailbox.speed = speed
		mailbox.hit.connect(_on_mailbox_hit)
		add_child(mailbox)


func spawn_coin() -> void:
	var coin: BikingMovingObject = COIN_LOAD.instantiate()
	coin.randomise_position()
	coin.position.x += randi_range(0, 48)
	add_child(coin)
	coin.speed = speed
	coin.coin_got.connect(_on_coin_collected)


func spawn_snail() -> void:
	if current_perk == "snail_repel" and randf() <= 0.95 and not currently_hell:
		return
	var snail: BikingMovingObject = SNAIL_LOAD.instantiate()
	snail.randomise_position()
	snail.will_delete.connect(_on_snail_hit)
	add_child(snail)
	snail.speed = speed
	snail.get_child(0).modulate = Color(randf(), randf(), randf())
	if currently_hell:
		snail.scale.x = -1.0


func the_kiosk() -> void:
	if currently_hell or kiosk_activated:
		return
	kiosk_activated = true
	var kiosk: BikingMovingObject = preload("res://scenes/biking/moving_objects/scn_mail_kiosk.tscn").instantiate()
	current_kiosk = kiosk
	add_child(kiosk)
	kiosk.approached.connect(_on_mailman_approached)
	kiosk.finished.connect(_on_mail_menu_finished)
	kiosk.will_delete.connect(_on_kiosk_will_delete)
	kiosk.speed = speed
	kiosk.global_position.y = 68
	kiosk.global_position.x = 80
	kiosk.global_position.x += speed * get_process_delta_time() * get_distance(KIOSK_BUFFER)


func check_if_kiosk_has_made_it() -> void:
	if not is_instance_valid(current_kiosk): return
	if current_kiosk.global_position.x > 156:
		var tw := create_tween()
		tw.tween_property(current_kiosk, "global_position:x", 80.0, 1.0)


func get_meter() -> float:
	return distance / 20.0


func get_distance(meter: float) -> int:
	return roundi(meter * 20)


func _on_mailbox_hit() -> void:
	mail_hits += 1
	silver_collected += 1
	update_ui()


func _on_mailman_approached() -> void:
	if currently_hell: return
	set_speed(0)
	bike.paused = true
	kiosks_activated += 1


func _on_mail_menu_finished() -> void:
	# if at the end of the road
	if get_meter() >= ROAD_LENGTH - 15:
		#var rew := calculate_rewards()
		DAT.incri("snail_hells_survived", hells_survived)
		#rew.grant()
		LTS.gate_id = LTS.GATE_EXIT_BIKING
		LTS.level_transition(LTS.ROOM_SCENE_PATH % DAT.get_data("current_room", "test_room"), {
			biking_results = {
				mail_hits = mail_hits,
				silver_collected = silver_collected,
				hells_survived = hells_survived,
				inventory = inventory,
				bike_hits = bike.hits,
				bike_health_proportion = bike.health / roundf(ResMan.get_character("greg").max_health),
				kiosks_activated = kiosks_activated,
			}
		})
		DAT.incri("biking_games_finished", 1)
		return

	bike.paused = false
	kiosk_activated = false
	set_speed(60)
	# applying perks
	if current_perk == "fast_earner":
		set_speed(80)
	elif current_perk == "super_mail":
		bike.mail_mode = bike.MailModes.SUPER
	elif current_perk == "mail_attraction":
		bike.mail_mode = bike.MailModes.FOLLOW
	elif current_perk == "sauce_mail":
		bike.mail_mode = bike.MailModes.SAUCE
	elif current_perk == "snail_bail":
		snails_hit = 0
		update_ui()


func _on_coin_collected() -> void:
	silver_collected += 1
	SND.play_sound(preload("res://sounds/coin.ogg"), {"pitch_scale": randf_range(0.9, 1.2)})
	update_ui()


func _on_snail_hit() -> void:
	if currently_syrup:
		return
	snails_hit += 1
	update_ui()
	SND.play_sound(preload("res://sounds/biking_snail_crush.ogg"), {"pitch_scale": randf_range(0.9, 1.2)})
	if snails_hit >= snails_until_hell and not currently_hell:
		enter_hell()
	if currently_hell and snails_hit >= snails_to_escape_hell:
		exit_hell()


func update_ui() -> void:
	ui.display_coins(silver_collected)
	ui.display_mail(mail_hits)
	if not currently_hell:
		ui.display_snail(snails_hit)
	else:
		ui.display_hell_snail(snails_hit)
		ui.display_hell_time(hell_time)


# once the kiosk goes offscreen
func _on_kiosk_will_delete() -> void:
	kiosk_activated = false


func _set_perk(to: String) -> void:
	current_perk = to


func open_inventory() -> void:
	if bike.health <= 0.0:
		return
	if speed < 5:
		return
	bike.paused = true
	speed_before_inv = speed
	set_speed(0)
	ui.open_item_menu()


func close_inventory() -> void:
	if bike.health <= 0.0:
		return
	bike.paused = false
	set_speed(speed_before_inv)
	ui.close_item_menu()


func enter_hell() -> void:
	currently_hell = true
	speed_before_snail = speed
	snails_hit = 0
	ui.display_hell_snail(snails_hit)
	set_speed(80)
	if currently_syrup:
		stop_syrup()
	ui.open_hell_menu()
	SND.play_song("snail_mourning", 4.0, {"skip_to": SND.get_music_playback_position()})
	hell_time = 0
	punishment_timer.start(1.0)
	var tw := create_tween().set_parallel()
	tw.tween_property(background_snail_hell, "position:y", 50.0, 2.0)
	tw.tween_property(background_sky, "modulate", Color.RED, 2.0)
	tw.tween_property(colour_changer, "color", HELL_COLOUR, 2.0)


func exit_hell() -> void:
	set_speed(speed_before_snail)
	ui.close_hell_menu()
	snails_hit = 0
	snails_until_hell += 15
	snails_to_escape_hell += 30
	SND.play_song("mail_mission", 4.0, {"skip_to": SND.get_music_playback_position()})
	set_deferred("currently_hell", false)
	punishment_timer.stop()
	silver_collected += maxi(75 - maxi(hell_time - 60, 0), 0)
	hells_survived += 1
	update_ui()
	var tw := create_tween().set_parallel()
	tw.tween_property(background_snail_hell, "position:y", 120.0, 2.0)
	tw.tween_property(background_sky, "modulate", Color("#8bc0ff"), 2.0)
	tw.tween_property(colour_changer, "color", Color.WHITE, 2.0)
	get_tree().get_nodes_in_group("snail_lasers").map(func(a): a.play_beam())
	get_tree().get_nodes_in_group("biking_houses").map(func(a): a.set_snail(false))


func _on_punishment_timer_timeout() -> void:
	hell_time += 1
	update_ui()


# skip 100m of road
var currently_syrup := false
var syrup_stop_meter := 0
func syrup():
	if currently_hell:
		bike.heal(12)
		return
	syrup_stop_meter = int(get_meter() + 100)
	currently_syrup = true
	set_speed(speed + 800)
	bike.invincibility_timer.start(8)

func stop_syrup():
	currently_syrup = false
	set_speed(speed - 800)
	bike.invincibility_timer.stop()


func coinify_snails() -> void:
	SND.play_sound(preload("res://sounds/biking_snail_coinify.ogg"))
	for snail in get_tree().get_nodes_in_group("biking_snails"):
		var coin := COIN_LOAD.instantiate()
		add_child(coin)
		coin.transform = snail.transform
		coin.modulate = snail.get_child(0).modulate
		coin.speed = speed
		coin.coin_got.connect(_on_coin_collected)
		SOL.vfx("dustpuff", coin.global_position, {parent = coin})
		snail.queue_free()
