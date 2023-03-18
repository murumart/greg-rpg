extends CharacterBody2D
class_name PlayerOverworld

enum States {FREE_MOVE, NOT_FREE_MOVE}
enum Rots {UP = -1, RIGHT, DOWN, LEFT}

const SPEED := 2600
const INTERACTION_LENGTH := 8
const ROTS = [&"up", &"right", &"down", &"left"]

var input := Vector2()
var state : int: set = set_state

@onready var raycast : RayCast2D = $InteractionRay
@onready var sprite : AnimatedSprite2D = $Sprite

var menu : Control = preload("res://scenes/gui/scn_overworld_menu.tscn").instantiate()


func _ready() -> void:
	if DAT.player_capturers.size() > 0:
		state = States.NOT_FREE_MOVE
	menu.close_requested.connect(_on_menu_close_requested)
	SOL.add_ui_child(menu)
	menu.hide()
	if LTS.gate_id in LTS.PLAYER_POSITION_LOAD_GATES:
		position = DAT.A.get(save_key_name("position"), position)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("ui_menu"):
			if (not menu.visible) and not "save_screen" in DAT.player_capturers:
				menu.call_deferred("showme")
				DAT.capture_player("overworld_menu")
			else:
				menu.call_deferred("hideme")
				DAT.free_player("overworld_menu")


func _physics_process(delta: float) -> void:
	input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	velocity = Vector2()
	if state == States.FREE_MOVE:
		movement(delta)
		if input: direct_raycast()
		if Input.is_action_just_pressed("ui_accept"):
			interact()
		direct_animation()


func set_state(to: States) -> void:
	state = to
	if not is_inside_tree(): return
	direct_animation()


func movement(delta: float) -> void:
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
	if DAT.player_capturers.size() > 0: return
	raycast.force_raycast_update()
	var collider := raycast.get_collider()
	#print(collider)
	if is_instance_valid(collider) and collider.has_method("interacted"):
		collider.call("interacted")


func _save_me() -> void:
	DAT.set_data(save_key_name("position"), position)


func save_key_name(key: String) -> String:
	return str("player_in_", DAT.get_current_scene().name.to_snake_case(), "_", key)


func _on_menu_close_requested() -> void:
	menu.call_deferred("hideme")
	DAT.free_player("overworld_menu")
