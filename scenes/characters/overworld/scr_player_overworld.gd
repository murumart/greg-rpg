class_name PlayerOverworld extends CharacterBody2D

enum States {FREE_MOVE, NOT_FREE_MOVE}
enum MoveModes {WALK, SKATE}
enum Rots {UP = -1, RIGHT, DOWN, LEFT}

@export var saving_disabled := false: set = set_saving_disabled

const SPEED := 3800
const INTERACTION_LENGTH := 8
const ROTS = [&"up", &"right", &"down", &"left"]

var input := Vector2()
var state : int: set = set_state
var move_mode : MoveModes = MoveModes.SKATE:
	set(to):
		move_mode = to
		skateboard.visible = bool(int(to))

@onready var raycast : RayCast2D = $InteractionRay
@onready var sprite : AnimatedSprite2D = $Sprite
@onready var skateboard: Sprite2D = $Skateboard

@onready var armour := $ArmorLayer
var updating_armour := false

var menu : Control = preload("res://scenes/gui/scn_overworld_menu.tscn").instantiate()


func _ready() -> void:
	DAT.player_captured.connect(_update_capture)
	DAT.get_character("greg").message_owner.connect(_character_message_received)
	if DAT.player_capturers.size() > 0:
		state = States.NOT_FREE_MOVE
	move_mode = DAT.get_data("player_move_mode", 0) as MoveModes
	menu.close_requested.connect(close_menu)
	SOL.add_ui_child(menu)
	menu.hide()
	if LTS.gate_id in LTS.PLAYER_POSITION_LOAD_GATES:
		position = DAT.get_data(get_save_key("position"), position)
	load_armour()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# opening the menu
		if event.is_action_pressed("ui_menu"):
			if (not menu.visible) and DAT.player_capturers.is_empty():
				menu.call_deferred("showme")
				DAT.capture_player("overworld_menu")
				DAT.set_data("has_opened_inventory", true)
			else:
				close_menu()


func _physics_process(delta: float) -> void:
	input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if state == States.FREE_MOVE:
		movement(delta)
		if input: direct_raycast()
		if Input.is_action_just_pressed("ui_accept"):
			interact()
		direct_animation()
	if updating_armour:
		armour.animation = sprite.animation
		armour.frame = sprite.frame


func set_state(to: States) -> void:
	state = to
	if not is_inside_tree(): return
	direct_animation()


func movement(delta: float) -> void:
	match move_mode:
		MoveModes.WALK:
			velocity = Vector2()
			velocity = input * SPEED * delta
			var _collided := move_and_slide()
			
		MoveModes.SKATE:
			if input:
				velocity = velocity.move_toward(input * SPEED * 3 * delta, delta * 64)
			else:
				velocity = velocity.move_toward(Vector2(), delta * 64)
			var collided := move_and_slide()
			if collided:
				velocity *= 0.5
	#if not input:
	global_position.x = roundi(global_position.x)
	global_position.y = roundi(global_position.y)


func direct_raycast() -> void:
	raycast.target_position = input.normalized() * INTERACTION_LENGTH


func direct_animation() -> void:
	var dir := Math.dir_from_rot(raycast.target_position.angle())
	var animation_name := str("walk_", ROTS[dir + 1])
	sprite.play(animation_name)
	sprite.speed_scale = 0.0
	if move_mode != MoveModes.SKATE:
		sprite.speed_scale = velocity.length_squared() * 0.00056
		if is_zero_approx(velocity.length_squared()):
			sprite.stop()
	else:
		skateboard.region_rect.position.y = 0 if absi(dir) != 1 else 16


# for cutscenes and such
func animate(animation_name: String) -> void:
	if not animation_name.length():
		sprite.stop()
	sprite.play(animation_name)
	sprite.speed_scale = 1.0


func interact() -> void:
	var collider : Object
	if DAT.player_capturers.size() > 0: return
	raycast.set_collision_mask_value(3, false)
	raycast.set_collision_mask_value(4, true)
	raycast.force_raycast_update()
	collider = raycast.get_collider()
	print(collider)
	if is_instance_valid(collider) and collider.has_method("interacted"):
		collider.call("interacted")
		return
	raycast.set_collision_mask_value(3, true)
	raycast.set_collision_mask_value(4, false)
	raycast.force_raycast_update()
	collider = raycast.get_collider()
	print(collider)
	if is_instance_valid(collider) and collider.has_method("interacted"):
		collider.call("interacted")
	#print(collider)
	# the interaction areas have the interacted function that this calls


func _update_capture(capture: bool) -> void:
	if capture:
		state = States.NOT_FREE_MOVE
		return
	state = States.FREE_MOVE


func _character_message_received(msg := &"") -> void:
	match msg:
		&"skateboard_equipped":
			move_mode = MoveModes.SKATE
			close_menu()


func _save_me() -> void:
	DAT.set_data(get_save_key("position"), position)
	DAT.set_data("player_move_mode", int(move_mode))


func get_save_key(key: String) -> String:
	return str("player_in_", LTS.get_current_scene().name.to_snake_case(), "_", key)


func close_menu() -> void:
	menu.call_deferred("hideme")
	DAT.free_player("overworld_menu")
	load_armour()


func set_saving_disabled(to: bool) -> void:
	saving_disabled = to
	menu.saving_disabled = to


func load_armour() -> void:
	armour.hide()
	updating_armour = false
	var greg := DAT.get_character("greg") as Character
	var path := "res://resources/armours/sfr_%s.tres" % greg.armour
	if greg.armour:
		if ResourceLoader.exists(path):
			armour.sprite_frames = load(path)
			updating_armour = true
			armour.show()
