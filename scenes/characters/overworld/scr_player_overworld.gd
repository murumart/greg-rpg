extends CharacterBody2D
class_name PlayerOverworld

enum States {FREE_MOVE, NOT_FREE_MOVE}
enum Rots {UP = -1, RIGHT, DOWN, LEFT}

const SPEED := 2600
const INTERACTION_LENGTH := 16
const ROTS = [&"up", &"right", &"down", &"left"]

var input := Vector2()
var state : int

@onready var raycast : RayCast2D = $InteractionRay
@onready var sprite : AnimatedSprite2D = $Sprite

var menu : Control = preload("res://scenes/gui/scn_overworld_menu.tscn").instantiate()


func _ready() -> void:
	SOL.add_ui_child(menu)
	menu.hide()
	if LTS.gate_id in LTS.PLAYER_POSITION_LOAD_GATES:
		position = DAT.A.get(save_key_name("position"), position)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("ui_menu"):
			if not menu.visible:
				menu.call_deferred("show")
				DAT.capture_player()
			else:
				menu.call_deferred("hide")
				DAT.free_player()


func _physics_process(delta: float) -> void:
	input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if state == States.FREE_MOVE:
		movement(delta)
		if input: direct_raycast()
		if Input.is_action_just_pressed("ui_accept"):
			interact()
	
	direct_animation()


func movement(delta: float) -> void:
	velocity = Vector2()
	
	velocity = input * SPEED * delta
	
	var _collided := move_and_slide()
	
	global_position.x = roundi(global_position.x)
	global_position.y = roundi(global_position.y)


func direct_raycast() -> void:
	raycast.target_position = input.normalized() * INTERACTION_LENGTH


func direct_animation() -> void:
	var animation_name := str("walk_", ROTS[Math.dir_from_rot(raycast.target_position.angle()) + 1])
	sprite.play(animation_name)
	sprite.speed_scale = 1.0
	sprite.speed_scale = velocity.length_squared() * 0.0006
	if is_zero_approx(velocity.length_squared()):
		sprite.stop()


func interact() -> void:
	var collider := raycast.get_collider()
	if is_instance_valid(collider) and collider.has_method("interacted"):
		collider.call("interacted")
	print("" if not collider else collider.name)


func _save_me() -> void:
	DAT.set_data(save_key_name("position"), position)


func save_key_name(key: String) -> String:
	return str("player_in_", DAT.get_current_scene().name, "_", key)
