class_name BikingGame extends Node2D

const ROAD_BOUNDARIES := Rect2(Vector2(2, 116), Vector2(158, 72))

const ROAD_LENGTH := 800.0
const MAIL_KIOSK_INTERVAL := 200

const SNAILS_UNTIL_HELL := 2
const SNAILS_TO_ESCAPE_HELL := 120

@onready var road := $Road
var speed := 60

var speed_before_inv := 0
var speed_before_snail := 0

@onready var bike := $Bike

@onready var ui := $UI

@onready var obstacle_timer := $ObstacleTimer
@onready var coin_timer := $CoinTimer
@onready var snail_timer := $SnailTimer
@onready var mailbox_timer := $MailboxTimer
const OBSTACLE_PACKED : Array[PackedScene] = [
	preload("res://scenes/biking/moving_objects/scn_obstacle_pothole.tscn"),
	preload("res://scenes/biking/moving_objects/scn_obstacle_log.tscn"),
]
const MAIL_BOX_LOAD := preload("res://scenes/biking/moving_objects/scn_biking_mailbox.tscn")
const COIN_LOAD := preload("res://scenes/biking/moving_objects/scn_biking_coin.tscn")
const SNAIL_LOAD := preload("res://scenes/biking/moving_objects/scn_biking_snail.tscn")

var distance := 0.0
var stop_meter := -1.0
var kiosk_activated := false:
	set(to):
		kiosk_activated = to
		print("kiosk activated: ", to)

var inventory := []

var mail_hits := 0
var silver_collected := 0
var snails_hit := 0
var current_perk := "": set = _set_perk
var currently_hell := false


func _ready() -> void:
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
	ui.display_health(bike.max_health)


func _physics_process(delta: float) -> void:
	road.global_position.x = wrapf(road.global_position.x - (speed * delta), -16, 32)
	distance += speed * delta * int(not currently_hell)
	ui.set_pointer_pos(get_meter() / ROAD_LENGTH)
	
	if (roundi(get_meter() + 20) % MAIL_KIOSK_INTERVAL) == 0:
		the_kiosk()
	
	if roundi(get_meter() + 5) % MAIL_KIOSK_INTERVAL == 0:
		current_perk = ""
		set_speed(60)
		bike.super_mail = false
		bike.following_mail = false
	
	if Input.is_action_just_pressed("ui_menu") and !ui.inventory_open:
		open_inventory()
	
	if (Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_menu")) and ui.inventory_open:
		close_inventory()


func set_speed(to: int) -> void:
	speed = to
	get_tree().set_group("speedsters", "speed", speed)
	$Bike/RoadCollision.constant_linear_velocity.x = -speed


func _on_died() -> void:
	set_speed(0)


func _on_obstacle_timer_timeout() -> void:
	if speed < 5: return
	# obstacle
	var obstacle_positions := []
	obstacle_timer.start(1.5)
	var obstacle : BikingObstacle = OBSTACLE_PACKED.pick_random().instantiate()
	obstacle.speed = speed
	obstacle.randomise_position()
	add_child(obstacle)
	obstacle_positions.append(obstacle.global_position)
	if obstacle.name.contains("Log"):
		obstacle.rotation = randf_range(-TAU, TAU)
		if current_perk == "log_repel" and randf() <= 0.95:
			obstacle.queue_free()
	if obstacle.name.contains("Pothole"):
		if current_perk == "nicer_roads" and randf() <= 0.95:
			obstacle.queue_free()


func _on_coin_timer_timeout() -> void:
	if currently_hell: return
	coin_timer.start(2)
	for i in 1 + (int(current_perk == "fast_earner") * randi() % 3):
		if randf() <= 0.5:
			spawn_coin()
			if randf() <= 0.33:
				spawn_coin()
				if randf() <= 0.33:
					spawn_coin()


func _on_snail_timer_timeout() -> void:
	snail_timer.start(randf_range(2, 5) * 0.1 if currently_hell else 1.0)
	spawn_snail()


func _on_mailbox_timer_timeout() -> void:
	mailbox_timer.start(4.0)
	if currently_hell: return
	if randf() <= 0.33:
		var mailbox : BikingMovingObject = MAIL_BOX_LOAD.instantiate()
		mailbox.global_position = Vector2(176, 68)
		mailbox.speed = speed
		mailbox.hit.connect(_on_mailbox_hit)
		add_child(mailbox)


func spawn_coin() -> void:
	var coin : BikingMovingObject = COIN_LOAD.instantiate()
	coin.randomise_position()
	add_child(coin)
	coin.speed = speed
	coin.coin_got.connect(_on_coin_collected)


func spawn_snail() -> void:
	var snail : BikingMovingObject = SNAIL_LOAD.instantiate()
	snail.randomise_position()
	snail.will_delete.connect(_on_snail_hit)
	add_child(snail)
	snail.speed = speed
	snail.get_node("Sprite2D").modulate = Color(randf(), randf(), randf())


func the_kiosk() -> void:
	if currently_hell: return
	if kiosk_activated: return
	print("kiosk starting")
	kiosk_activated = true
	var kiosk : BikingMovingObject = preload("res://scenes/biking/moving_objects/scn_mail_kiosk.tscn").instantiate()
	add_child(kiosk)
	kiosk.approached.connect(_on_mailman_approached)
	kiosk.finished.connect(_on_mail_menu_finished)
	kiosk.will_delete.connect(_on_kiosk_will_delete)
	kiosk.speed = speed
	kiosk.global_position.y = 68
	kiosk.global_position.x = 80
	kiosk.global_position.x += speed * get_process_delta_time() * get_distance(20)


func get_meter() -> float:
	return distance / 20.0


func get_distance(meter: float) -> int:
	return roundi(meter * 20)


func _on_mailbox_hit() -> void:
	mail_hits += 1
	update_ui()


func _on_mailman_approached() -> void:
	set_speed(0)
	bike.paused = true


func _on_mail_menu_finished() -> void:
	set_speed(60)
	bike.paused = false
	kiosk_activated = false
	if current_perk == "fast_earner":
		set_speed(80)
	elif current_perk == "super_mail":
		bike.super_mail = true
	elif current_perk == "mail_attraction":
		bike.following_mail = true


func _on_coin_collected() -> void:
	silver_collected += 1
	SND.play_sound(preload("res://sounds/snd_coin.ogg"), {"pitch": randf_range(0.9, 1.2)})
	update_ui()


func _on_snail_hit() -> void:
	snails_hit += 1
	update_ui()
	SND.play_sound(preload("res://sounds/snd_biking_snail_crush.ogg"), {"pitch": randf_range(0.9, 1.2)})
	if currently_hell: return
	if snails_hit >= SNAILS_UNTIL_HELL:
		enter_hell()


func update_ui() -> void:
	ui.display_coins(silver_collected)
	ui.display_mail(mail_hits)
	if not currently_hell:
		ui.display_snail(snails_hit)
	else:
		ui.display_hell_snail(snails_hit)


func _on_kiosk_will_delete() -> void:
	kiosk_activated = false


func _set_perk(to: String) -> void:
	current_perk = to


func open_inventory() -> void:
	speed_before_inv = speed
	set_speed(0)
	ui.open_item_menu()


func close_inventory() -> void:
	set_speed(speed_before_inv)
	ui.close_item_menu()


func enter_hell() -> void:
	currently_hell = true
	speed_before_snail = speed
	snails_hit = 0
	ui.display_hell_snail(snails_hit)
	set_speed(80)
	ui.open_hell_menu()


func exit_hell() -> void:
	currently_hell = false
	set_speed(speed_before_snail)
	ui.close_hell_menu()
	snails_hit = 0
	update_ui()




