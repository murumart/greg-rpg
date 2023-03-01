class_name BikingGame extends Node2D

const ROAD_BOUNDARIES := Rect2(Vector2(2, 116), Vector2(158, 72))

const ROAD_LENGTH := 400.0
const MAIL_KIOSK_INTERVAL := 40

@onready var road := $Road
var speed := 60

@onready var bike := $Bike

@onready var ui := $UI

@onready var obstacle_timer := $ObstacleTimer
var obstacle_packed : Array[PackedScene] = [
	preload("res://scenes/biking/moving_objects/scn_obstacle_pothole.tscn")
]

var distance := 0.0
var stop_meter := -1.0
var kiosk_activated := false


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
	
	if (roundi(get_meter()) % MAIL_KIOSK_INTERVAL) == 0 and get_meter() > MAIL_KIOSK_INTERVAL:
		set_speed(0)
		bike.speed = 60


func set_speed(to: int) -> void:
	speed = to
	get_tree().set_group("speedsters", "speed", speed)


func _on_died() -> void:
	set_speed(0)


func _on_obstacle_timer_timeout() -> void:
	if speed < 5: return
	obstacle_timer.start(randf_range(randf(), speed / 200.0))
	var obstacle : BikingObstacle = obstacle_packed.pick_random().instantiate()
	obstacle.speed = speed
	obstacle.global_position = Vector2(176, randi_range(76, 112))
	add_child(obstacle)


func the_kiosk() -> void:
	if kiosk_activated: return
	print("kiosk starting")
	kiosk_activated = true
	var kiosk : BikingMovingObject = preload("res://scenes/biking/moving_objects/scn_mail_kiosk.tscn").instantiate()
	add_child(kiosk)
	kiosk.speed = speed
	kiosk.global_position.y = 68
	kiosk.global_position.x = 80
	kiosk.global_position.x += speed * get_process_delta_time() * get_distance(20)


func get_meter() -> float:
	return distance / 20.0


func get_distance(meter: float) -> int:
	return roundi(meter * 20)

