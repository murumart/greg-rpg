extends Node2D

# cars that drive around and hit people (you (greg))

signal paused
signal resumed

enum Rots {UP = -1, RIGHT, DOWN, LEFT}
# different rotations are in the same sprite sheet
var regions := []
const SHAPE_SIZES := [Vector2i(26, 10), Vector2i(10, 20)]

@onready var sprite: Sprite2D = $Sprite
@onready var collision_area: Area2D = $CollisionArea
@onready var collision_shape: CollisionShape2D = $CollisionArea/CollisionShape

@export var path_container: Node
@export var moves := true: set = set_moves

@export var speed := 100.0

@export var disable_saving := false

@export_group("Appearance")
@export var custom_texture: Texture2D
@export_color_no_alpha var color := Color(1, 1, 1, 1)

var target := Vector2()
var current_target := 0
var velocity := Vector2()

var battle_info: BattleInfo


func _ready() -> void:
	texture_setup()
	if DAT.get_data(get_save_key("fought"), false):
		self.global_position = Vector2(293123, 819474)
		set_physics_process(false)
		collision_area.monitoring = false
		hide()
		return
	if not moves:
		$VroomVroom.stop()
	collision_area.body_entered.connect(_on_collided_with_player)
	position = DAT.get_data(get_save_key("position"), position)
	current_target = DAT.get_data(get_save_key("current_target"), current_target)
	battle_info = BattleInfo.new().set_enemies(["car"]).set_background("cars")\
	.set_music("overrun").set_death_reason("car")
	set_color(color)
	set_target(0)


func _physics_process(delta: float) -> void:
	if moves:
		# moving towards the target
		global_position = global_position.move_toward(target, delta * speed)
		turn(int(global_position.angle_to_point(target)))
		# once reached the target
		if global_position.distance_squared_to(target) < 2:
			set_target(1)


func set_target(add: int) -> void:
	if not moves: return
	var path_points := path_container.get_children()
	var pause := path_container.get_child(
		current_target).get_meta("pause", 0) as int
	if pause:
		moves = false
		paused.emit()
		get_tree().create_timer(pause).timeout.connect(
			func(): moves = true; resumed.emit())
	if path_points:
		current_target = wrapi(current_target + add, 0, path_points.size())
		target = (path_points[current_target].global_position)


# this implementation means there should be plenty of nodes in the path
# since the previous node or an unrelated node might be closer than the next node
# this matters when loading the scene
func at_which_path_point() -> Node2D:
	var path_points := path_container.get_children()
	if path_points:
		path_points.sort_custom(sort_by_distance)
		return path_points.front()
	return null


func _on_collided_with_player(_player) -> void:
	if not moves: return
	# cars don't spawncamp
	if DAT.seconds - DAT.load_second < 2: return
	moves = false
	var skateboard_check := LTS.skateboard_check()
	if not skateboard_check:
		DAT.set_data("last_hit_car_color", color) # used in battle to set the car's colour
		DAT.set_data("last_hit_car_name", name.to_snake_case())
		DAT.set_data(get_save_key("fought"), true)
		LTS.enter_battle(battle_info)
	else:
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 1.0, 2.0).from(0.5)
		tw.tween_callback(func(): moves = true)


func turn(rot: int) -> void:
	var dir := Math.dir_from_rot(rot)
	sprite.region_rect = regions[dir + 1]
	collision_shape.shape.size = SHAPE_SIZES[int((dir + 1) % 2 == 0)]
 

func set_color(to: Color) -> void:
	color = to
	sprite.self_modulate = color


func _save_me() -> void:
	if disable_saving: return
	DAT.set_data(get_save_key("position"), position)
	DAT.set_data(get_save_key("current_target"), current_target)


func get_save_key(key: String) -> String:
	return str("car_", name, "_in_", LTS.get_current_scene().name.to_snake_case(), "_", key)


func set_moves(to: bool):
	moves = to
	var vroom := get_node_or_null("VroomVroom") # did i really name it that
	# goddamn vroom
	if vroom:
		vroom.playing = to


func sort_by_distance(a: Node2D, b: Node2D) -> bool:
	return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)


func texture_setup() -> void:
	if custom_texture:
		sprite.texture = custom_texture
	var sx := sprite.texture.get_width()
	var sy := sprite.texture.get_height()
	regions = [
		Rect2i((sx / 4) * 3, 0, sx / 4, sy),
		Rect2i(0, 0, sx / 2, sy / 2),
		Rect2i(sx / 2, 0, sx / 4, sy),
		Rect2i(0, sy / 2, sx / 2, sy / 2)]
	

