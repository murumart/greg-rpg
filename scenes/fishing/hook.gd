extends Node2D

const FG = preload("res://scenes/fishing/scr_fishing_minigame.gd")

signal fish_caught
signal item_caught(type: StringName)
signal hit

@export var line_drawer: Node2D

@onready var hook_collision: Area2D = $HookCollision

@onready var hook_animator: AnimationPlayer = $HookAnimator
@onready var crash_sound: AudioStreamPlayer = $CrashSound
@onready var hook_sprite_sub: Sprite2D = $Look/Look2
@onready var hook_sprite_main: Sprite2D = $Look

var state: FG.States

var speed: float
var hook_speed: float = 80.0
var hook_data := BattlePayloadFishing.new()
var hook_positions: PackedVector2Array


func _ready() -> void:
	line_drawer.draw.connect(_on_line_draw)
	$HookCollision.body_entered.connect(_on_hook_collision)
	$HookCollision.area_entered.connect(_on_hook_collision)


func _physics_process(delta: float) -> void:
	line_movement(delta)
	match state:
		FG.States.MOVE:
			hook_movement(delta)


func set_data(data: BattlePayloadFishing) -> void:
	hook_data = data
	$HookCollision/CollisionShape2D.shape.size = Vector2(2, 3) * hook_data.world_hitbox_size_multiplier
	if data.item_id:
		hook_sprite_main.texture = ResMan.get_item(hook_data.item_id).texture
		hook_sprite_sub.texture = ResMan.get_item(hook_data.item_id).texture


func hook_movement(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var movement := input * hook_speed * delta
	movement.x *= hook_data.horizontal_movement_speed_multiplier
	movement.y *= hook_data.vertical_movement_speed_multiplier
	global_position += movement
	global_position.y = clampf(global_position.y, -60, 50)
	global_position.x = clampf(global_position.x, -90, 90)
	# swaying left-right
	hook_sprite_main.rotation_degrees = move_toward(
		hook_sprite_main.rotation_degrees,
		input.x * 30,
		hook_speed * delta
			* (2 * int(
				not bool(input.x)
				or signf(hook_sprite_main.rotation_degrees) != signf(input.x)
			)) + 1)
	if Engine.get_physics_frames() % 4 == 0:
		hook_positions.append(global_position)


func _on_hook_collision(node: Node2D) -> void:
	var wiggle := func():
		hook_animator.advance(0)
		hook_animator.play("hit")
		SOL.shake(0.2)
	if state == FG.States.STOP:
		return
	# hitting an obstacle
	if node is TileMapLayer or node.get_parent().get("hazardous"):
		#get_tree().reload_current_scene()
		if node.get_parent().has_method("caught"):
			node.get_parent().call("caught")
			hide()
		crash_sound.play()
		SOL.shake(0.4)
		wiggle.call()
		hit.emit()
	# hitting a nice fish
	elif node is Area2D and node.get_parent() is FishingFish:
		node = node.get_parent() as FishingFish
		if node.moving and not node.decor:
			fish_caught.emit(node)
			wiggle.call()


func line_movement(delta: float) -> void:
	# slowly sway as the water moves
	for pos in hook_positions:
		var i := hook_positions.find(pos)
		pos.y -= (speed * delta * randf_range(0.8, 1.2)) if state == FG.States.MOVE else 0.0
		pos.x = move_toward(pos.x, global_position.x, delta * randf_range(2, 4))
		if pos.y < -66:
			hook_positions.remove_at(i)
		else:
			hook_positions[i] = pos
	line_drawer.queue_redraw()


func _on_line_draw() -> void:
	for i in hook_positions.size():
		var pos: Vector2 = hook_positions[i]
		line_drawer.draw_line(
			Vector2(0, -99) if i <= 0 else hook_positions[i - 1],
			pos if i < hook_positions.size() - 1 else global_position,
			Color.BLACK,
			1.0
		)
