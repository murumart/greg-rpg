class_name BikingGame extends Node2D

const ROAD_BOUNDARIES := Rect2(Vector2(2, 116), Vector2(158, 72))

const ROAD_LENGTH := 800.0
const MAIL_KIOSK_INTERVAL := 200

@onready var road := $Road
var speed := 60

@onready var bike := $Bike

@onready var ui := $UI

@onready var obstacle_timer := $ObstacleTimer
const OBSTACLE_PACKED : Array[PackedScene] = [
	preload("res://scenes/biking/moving_objects/scn_obstacle_pothole.tscn"),
	preload("res://scenes/biking/moving_objects/scn_obstacle_log.tscn"),
]
const MAIL_BOX_LOAD := preload("res://scenes/biking/moving_objects/scn_biking_mailbox.tscn")
const COIN_LOAD := preload("res://scenes/biking/moving_objects/scn_biking_coin.tscn")

var distance := 0.0
var stop_meter := -1.0
var kiosk_activated := false

var mail_hits := 0
var silver_collected := 0
var current_perk := "": set = _set_perk


func _ready() -> void:
	bike.died.connect(_on_died)
	obstacle_timer.start()
	set_speed(speed)


func _physics_process(delta: float) -> void:
	road.global_position.x = wrapf(road.global_position.x - (speed * delta), -16, 32)
	distance += speed * delta
	ui.set_pointer_pos(get_meter() / ROAD_LENGTH)
	
	if (roundi(get_meter() + 20) % MAIL_KIOSK_INTERVAL) == 0:
		the_kiosk()


func set_speed(to: int) -> void:
	speed = to
	get_tree().set_group("speedsters", "speed", speed)
	$Bike/RoadCollision.constant_linear_velocity.x = -speed


func _on_died() -> void:
	set_speed(0)


func _on_obstacle_timer_timeout() -> void:
	if speed < 5: return
	# obstacle
	obstacle_timer.start(1.5)
	var obstacle : BikingObstacle = OBSTACLE_PACKED.pick_random().instantiate()
	obstacle.speed = speed
	obstacle.global_position = Vector2(176, randi_range(76, 112))
	add_child(obstacle)
	if obstacle.name.contains("Log"):
		obstacle.rotation = randf_range(-TAU, TAU)
	# mailboxes
	if randf() <= 0.33:
		var mailbox : BikingMovingObject = MAIL_BOX_LOAD.instantiate()
		mailbox.global_position = Vector2(176, 68)
		mailbox.speed = speed
		mailbox.hit.connect(_on_mailbox_hit)
		add_child(mailbox)
	# coins
	if randf() <= 0.5:
		spawn_coin()
		if randf() <= 0.5:
			spawn_coin()


func spawn_coin() -> void:
	var coin : BikingMovingObject = COIN_LOAD.instantiate()
	add_child(coin)
	coin.speed = speed
	coin.coin_got.connect(_on_coin_collected)
	coin.global_position = Vector2(176, randi_range(76, 112))


func the_kiosk() -> void:
	if kiosk_activated: return
	print("kiosk starting")
	kiosk_activated = true
	var kiosk : BikingMovingObject = preload("res://scenes/biking/moving_objects/scn_mail_kiosk.tscn").instantiate()
	add_child(kiosk)
	kiosk.approached.connect(_on_mailman_approached)
	kiosk.finished.connect(_on_mail_menu_finished)
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


func _on_mailman_approached() -> void:
	set_speed(0)
	bike.paused = true


func _on_mail_menu_finished() -> void:
	set_speed(60)
	bike.paused = false
	kiosk_activated = false


func _on_coin_collected() -> void:
	silver_collected += 1


func _set_perk(to: String) -> void:
	current_perk = to

