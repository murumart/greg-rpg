extends Node2D

signal died

var speed := 200

var max_health := 100
var health := 100

@onready var nodes := $Greg
@onready var wheels := [$Lwheel, $Rwheel]

@onready var pedal_animator := $Greg/PedalingAnimation
@onready var peas := $Greg/Head/Peas


func _ready() -> void:
	set_ragdoll_enabled(false)
	max_health = roundi(DAT.get_character("greg").max_health)
	health = roundi(DAT.get_character("greg").health)


func _physics_process(delta: float) -> void:
	var old_position := global_position
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	global_position += Vector2(input) * speed * delta
	global_position.x = clampf(global_position.x, BikingGame.ROAD_BOUNDARIES.position.x, BikingGame.ROAD_BOUNDARIES.size.x)
	global_position.y = clampf(global_position.y, BikingGame.ROAD_BOUNDARIES.size.y, BikingGame.ROAD_BOUNDARIES.position.y)
	for w in wheels:
		w.rotation = w.rotation + speed * delta * 0.25 * (Vector2(input.x + 1, input.y).length() if not (global_position.x >= BikingGame.ROAD_BOUNDARIES.size.x or global_position.x <= BikingGame.ROAD_BOUNDARIES.position.x) else 1.0)
	
	if Input.is_action_just_pressed("ui_accept"):
		die()


func set_ragdoll_enabled(to: bool) -> void:
	for node in nodes.get_children():
		if node is PhysicsBody2D:
			node.set_deferred("freeze", !to)
	if !to:
		pedal_animator.play("pedaling")
	else:
		pedal_animator.stop()


func add_ragdoll_force(force: Vector2) -> void:
	for node in nodes.get_children():
		if node is RigidBody2D:
			node.apply_impulse(force + Vector2((randf_range(10, 20)), randf_range(-10, -20)))


func launch_ragdoll() -> void:
	set_ragdoll_enabled(true)
	call_deferred("add_ragdoll_force", Vector2(100, -100))


func hurt(amount: int) -> void:
	health = clamp(health - absi(amount), 0, max_health)
	if health <= 0:
		die()
	peas.emitting = true
	await get_tree().process_frame
	peas.emitting = false


func die() -> void:
	died.emit()
	launch_ragdoll()


func _on_collision_area_area_entered(area: Area2D) -> void:
	if not area.get_parent() is BikingObstacle: return
	var obstacle : BikingObstacle = area.get_parent()
	hurt(obstacle.damage)

