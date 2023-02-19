extends CharacterBody2D
class_name OverworldCharacter

# this is the overworld npcs class
# they can walk around, chase you, you can talk to them if they have dialogue

signal target_reached

enum Rots {UP = -1, RIGHT, DOWN, LEFT}
const ROTS := [&"up", &"right", &"down", &"left"]
enum States {IDLE, TALKING, WANDER, CHASE, PATH}
var state := States.IDLE

@export_group("Nodes")
@export var animated_sprite : AnimatedSprite2D
@export var collision_shape : CollisionShape2D
@export var collision_extents := Vector2i(8, 3): set = _set_collision_extents
@export var interaction_area : Area2D
@export var detection_area : Area2D
@export var detection_raycast : RayCast2D

@export_group("Movement")
@export var speed := 3500
@export var movement_wait := 5.0
@export var random_movement := false
const TIME_BETWEEN_CHASE_UPDATES := 0.25
@export var random_movement_distance := 64
var random_movement_timer : Timer
const RANDOM_MOVEMENT_TRIES := 16
var chase_timer : Timer
var time_moved := 0.0
@export var chase_target : Node2D
@export var chase_distance := 32
@export var path_container : Node2D
var path_timer : Timer

@export_group("Interaction")
@export var action_right_after_dialogue := false
@export var interact_on_touch := false
var convo_progress := 0
@export var default_lines : Array[StringName]
@export var battle_info : BattleInfo
@export var transport_to_scene := ""
var interactions := 0

@export_group("Save Information")
@export var character_link := -1
@export var save_position : bool = false
@export var save_convo_progess : bool = false
@export var permanently_defeated : bool = false

var target : Vector2 : set = set_target


func _ready() -> void:
	# load stuff
	if LTS.gate_id == LTS.GATE_LOADING:
		pass
	if save_position:
		set_position(DAT.get_data(save_key_name("position"), position))
	if save_convo_progess:
		convo_progress = DAT.A.get(save_key_name("convo_progress"), 0)
	if permanently_defeated:
		if character_link > -1:
			if character_link in DAT.A.get("defeated_characters", []):
				global_position = Vector2i(129731, 120947912)
				set_physics_process(false)
				hide()
				return
	# setup
	if random_movement:
		random_movement_timer = Timer.new()
		add_child(random_movement_timer)
		random_movement_timer.timeout.connect(_on_random_movement_timer_timeout)
		random_movement_timer.start(movement_wait)
	if not chase_target:
		detection_area.monitoring = false
	if chase_target:
		chase_timer = Timer.new()
		add_child(chase_timer)
		chase_timer.timeout.connect(_on_chase_timer_timeout)
		chase_timer.start(TIME_BETWEEN_CHASE_UPDATES)
	if path_container:
		path_timer = Timer.new()
		add_child(path_timer)
		path_timer.one_shot = true
		path_timer.timeout.connect(_on_path_target_reached)
		path_timer.start(movement_wait)
	if interact_on_touch:
		interaction_area.body_entered.connect(_on_interaction_area_on_interacted)
	detection_area.get_child(0).shape.radius = chase_distance
	detection_raycast.add_exception(detection_area)
	detection_raycast.add_exception(interaction_area)


func _physics_process(delta: float) -> void:
	match state:
		States.IDLE:
			velocity = Vector2()
		States.TALKING:
			# idle if no longer talking
			if not is_instance_valid(SOL.dialogue_box.loaded_dialogue) or SOL.dialogue_box.loaded_dialogue.size() < 1:
				set_state(States.IDLE)
		States.CHASE:
			velocity = global_position.direction_to(target) * delta * speed
			if global_position.distance_squared_to(target) > 6 and time_moved < 5:
				time_moved += delta * 2
				var _collided := move_and_slide()
			else:
				set_state(States.IDLE)
		States.WANDER:
			velocity = global_position.direction_to(target) * delta * speed * 0.75
			if global_position.distance_squared_to(target) > 4 and time_moved < 5:
				time_moved += delta * 2
				var _collided := move_and_slide()
			else:
				target_reached.emit()
				set_state(States.IDLE)
		States.PATH:
			velocity = global_position.direction_to(target) * delta * speed * 0.75
			if global_position.distance_squared_to(target) > 4 and time_moved < 5:
				time_moved += delta * 2
				var _collided := move_and_slide()
			else:
				target_reached.emit()
				path_timer.start(movement_wait)
				set_state(States.IDLE)
	
	direct_walking_animation(velocity)


func interacted() -> void:
	interactions += 1
	set_state(States.TALKING)
	velocity = Vector2()
	if default_lines.size() > 0:
		var continuing := true
		if convo_progress >= default_lines.size():
			if battle_info != null or transport_to_scene != "":
				continuing = false
			else:
				convo_progress -= 1
		if continuing:
			SOL.dialogue(default_lines[convo_progress])
			if not SOL.dialogue_closed.is_connected(_on_talking_finished):
				SOL.dialogue_closed.connect(_on_talking_finished)
			convo_progress = mini(convo_progress + 1, default_lines.size())
			return
	if battle_info:
		if convo_progress + 1 >= default_lines.size() or default_lines.size() < 1:
			LTS.enter_battle(battle_info)
			return
	if transport_to_scene:
		LTS.level_transition(transport_to_scene)
		return


func _on_talking_finished() -> void:
	if path_timer:
		set_state(States.PATH)
		path_timer.paused = false
	SOL.dialogue_closed.disconnect(_on_talking_finished)
	if action_right_after_dialogue:
		if battle_info:
			if convo_progress + 1 >= default_lines.size() or default_lines.size() < 1:
				LTS.enter_battle(battle_info)
		if transport_to_scene:
			LTS.level_transition(transport_to_scene)


func _on_random_movement_timer_timeout() -> void:
	if not state == States.IDLE: return
	if not random_movement: return
	for i in RANDOM_MOVEMENT_TRIES:
		set_target(global_position + Vector2(randi_range(-random_movement_distance, random_movement_distance), randi_range(-random_movement_distance, random_movement_distance)))
		detection_raycast.target_position = to_local(target)
		detection_raycast.force_raycast_update()
		var collider := detection_raycast.get_collider()
		if collider:
			target = detection_raycast.get_collision_point()
		else: break
	set_state(States.WANDER)


func _on_path_target_reached() -> void:
	if not state == States.IDLE: return
	var path_points := path_container.get_children()
	if path_points:
		var current := at_which_path_point()
		var current_index := path_points.find(current)
		var next_index := wrapi(current_index + 1, 0, path_points.size())
		set_target(path_points[next_index].global_position)
		set_state(States.PATH)


func at_which_path_point() -> Node2D:
	var path_points := path_container.get_children()
	if path_points:
		path_points.sort_custom(sort_by_distance)
		return path_points.front()
	return null


func set_state(to: States) -> void:
	state = to
	if to == States.CHASE:
		chase_timer.start(TIME_BETWEEN_CHASE_UPDATES)
	if to == States.IDLE:
		time_moved = 0.0
	if to == States.TALKING:
		if path_timer:
			path_timer.paused = true


func direct_walking_animation(direction: Vector2, complain := false) -> void:
	if complain: prints("direction:", direction)
	if complain: prints("angle:", Math.dir_from_rot(direction.angle()) + 1)
	if not is_instance_valid(animated_sprite): return
	var animation_name := str("walk_", ROTS[Math.dir_from_rot(direction.angle()) + 1]) if direction.length_squared() > 1 else "walk_down"
	animated_sprite.play(animation_name)
	animated_sprite.speed_scale = direction.length_squared() * 0.0006
	if is_zero_approx(direction.length_squared()):
		animated_sprite.stop()


func _set_collision_extents(to: Vector2i) -> void:
	collision_extents = to
	if collision_shape:
		collision_shape.shape.size = to
	if interaction_area:
		if interaction_area.get_child_count() > 0:
			var interaction_collision : CollisionShape2D = interaction_area.get_child(0)
			interaction_collision.shape.size.x = to.x + 2
			interaction_collision.shape.size.y = to.y + 2


func set_target(to: Vector2) -> void:
	target = to


func set_target_offset(to: Vector2, random := 5) -> void:
	target = to + Vector2(randf_range(-random, random), randf_range(-random, random))


func _on_detection_area_body_entered(body: Node2D) -> void:
	chase(body)


func chase(body: CollisionObject2D) -> void:
	if body == chase_target:
		# test if raycast can reach the target
		detection_raycast.target_position = to_local(body.global_position)
		detection_raycast.force_raycast_update()
		var collider := detection_raycast.get_collider()
		
		# test if the raycast is colliding with another npc who is chasing the same target
		var same_target_as_collider_condition : bool = false
		same_target_as_collider_condition = (is_instance_valid(collider) and "chase_target" in collider and collider.chase_target == chase_target)
		
		# we don't care if we collide with something that chases the same target
		if collider == chase_target or same_target_as_collider_condition:
			time_moved = 0.0
			set_target_offset(body.global_position if not same_target_as_collider_condition else body.global_position, 24) # if a bunch of npcs are chasing the same target, this will help make them not clump up together
			set_state(States.CHASE) # this also restarts the timer


func _on_chase_timer_timeout() -> void:
	var bodies := detection_area.get_overlapping_bodies()
	bodies.erase(self)
	for b in bodies:
		chase(b)
	if bodies.size() < 1:
		chase_timer.stop()


func debprint(msg) -> void:
	print("npc %s: " % name, msg)


func _on_interaction_area_on_interacted(_possible_body = false) -> void:
	interacted()


func _save_me() -> void:
	debprint("saving!")
	if save_position:
		DAT.set_data(save_key_name("position"), position)
	if save_convo_progess:
		DAT.set_data(save_key_name("convo_progress"), convo_progress)


func save_key_name(key: String) -> String:
	return str("npc_", name, "_in_", DAT.get_current_scene().name.to_snake_case(), "_", key)


func sort_by_distance(a: Node2D, b: Node2D) -> bool:
	return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
