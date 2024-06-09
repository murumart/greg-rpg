class_name PlayerOverworld extends CharacterBody2D

enum States {FREE_MOVE, NOT_FREE_MOVE}
enum MoveModes {WALK, SKATE}
enum Rots {UP = -1, RIGHT, DOWN, LEFT}

@export var saving_disabled := false: set = set_saving_disabled
@export var menu_disabled := false

const SPEED := 3800
const INTERACTION_LENGTH := 8
const ROTS = [&"up", &"right", &"down", &"left"]

var input := Vector2()
var state: int: set = set_state
var move_mode: MoveModes = MoveModes.WALK:
	set(to):
		move_mode = to
		skateboard.visible = bool(int(to))

@onready var raycast: RayCast2D = $InteractionRay
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var skateboard: Sprite2D = $Skateboard
@onready var cellphone := $Cellphone as Cellphone

@onready var armour := $ArmorLayer
var updating_armour := false

var menu: Control = preload("res://scenes/gui/scn_overworld_menu.tscn").instantiate()


func _ready() -> void:
	DAT.player_captured.connect(_update_capture)
	ResMan.get_character("greg").message_owner.connect(_character_message_received)
	if DAT.player_capturers.size() > 0:
		state = States.NOT_FREE_MOVE
	move_mode = DAT.get_data("player_move_mode", 0) as MoveModes
	menu.close_requested.connect(close_menu)
	menu.skateboard_dequipped.connect(func(): move_mode = MoveModes.WALK)
	SOL.add_ui_child(menu)
	menu.hide()
	load_armour()
	spawn_position()
	direct_animation()
	print("player ready")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		if (not menu.visible) and DAT.player_capturers.is_empty():
			if not menu_disabled:
				menu.call_deferred("showme")
				DAT.capture_player("overworld_menu")
				DAT.set_data("has_opened_inventory", true)
		else:
			close_menu()


func _physics_process(delta: float) -> void:
	input = Vector2()

	if state == States.FREE_MOVE:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if input: direct_raycast()
		if Input.is_action_just_pressed("ui_accept"):
			interact()
		direct_animation()
	movement(delta)
	if updating_armour:
		armour.animation = sprite.animation
		armour.frame = sprite.frame


func set_state(to: States) -> void:
	state = to
	if not is_inside_tree(): return
	#direct_animation()


func movement(delta: float) -> void:
	match move_mode:
		MoveModes.WALK:
			velocity = Vector2()
			velocity = input * SPEED * delta
			var _collided := move_and_slide()

		MoveModes.SKATE:
			if input:
				velocity = velocity.move_toward(input * SPEED * 3 * delta, delta * 128)
			else:
				velocity = velocity.move_toward(Vector2(), delta * 128)
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
	var animation_name : String = "walk_" + ROTS[dir + 1]
	sprite.play(animation_name)
	sprite.speed_scale = 0.0
	if move_mode != MoveModes.SKATE:
		sprite.speed_scale = velocity.length() * 0.04
		if is_zero_approx(velocity.length_squared()):
			sprite.stop()
	else:
		skateboard.region_rect.position.y = 0 if absi(dir) != 1 else 16


# for cutscenes and such
func animate(animation_name: String, moving := false) -> void:
	if not animation_name.length():
		sprite.stop()
	sprite.play(animation_name)
	sprite.speed_scale = 1.0 * float(moving)


func interact() -> void:
	var collider: Object
	if DAT.player_capturers.size() > 0: return
	raycast.set_collision_mask_value(3, false)
	raycast.set_collision_mask_value(4, true)
	raycast.force_raycast_update()
	collider = raycast.get_collider()
	if is_instance_valid(collider) and collider.has_method("interacted"):
		collider.call("interacted")
		return
	raycast.set_collision_mask_value(3, true)
	raycast.set_collision_mask_value(4, false)
	raycast.force_raycast_update()
	collider = raycast.get_collider()
	if is_instance_valid(collider) and collider.has_method("interacted"):
		collider.call("interacted")
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
			DAT.set_data("player_move_mode", int(move_mode))
			close_menu()
		&"cellphone_called":
			cellphone.phonecall()
			close_menu()


func _save_me() -> void:
	DAT.set_data(get_save_key("position"), position)
	DAT.set_data("player_move_mode", int(move_mode))


func get_save_key(key: String) -> String:
	var scene := LTS.get_current_scene() as Node
	return str("player_in_", scene.name.to_snake_case(), "_", key)


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
	var greg := ResMan.get_character("greg") as Character
	if greg.armour:
		var path := "res://resources/armours/sfr_%s.tres" % greg.armour
		if ResourceLoader.exists(path):
			armour.sprite_frames = load(path)
			updating_armour = true
			armour.show()


func spawn_position() -> void:
	if LTS.gate_id in LTS.PLAYER_POSITION_LOAD_GATES:
		position = DAT.get_data(get_save_key("position"), position)
	get_tree().call_group("room_gates", "apply_spawn_point", self)
