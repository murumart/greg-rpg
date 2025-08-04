extends StaticBody2D

const Emitter = preload("res://scenes/decor/sgpuzzle/light_emitter_block.gd")
const Receiver = preload("res://scenes/decor/sgpuzzle/light_receiver_block.gd")

@export_color_no_alpha var color: Color = Color.WHITE
@export var movable: bool

var light_sources: Array[Emitter]
var reset_position: Vector2
var _q_params: PhysicsShapeQueryParameters2D


func _ready() -> void:
	reset_position = global_position
	add_to_group(&"light_puzzle_elements")
	_q_params = PhysicsShapeQueryParameters2D.new()
	var shap := RectangleShape2D.new()
	shap.size = Vector2(15.5, 15.5)
	_q_params.shape = shap


func reset_puzzle() -> void:
	for g: Receiver in get_tree().get_nodes_in_group(&"light_puzzle_elements"):
		g.global_position = g.reset_position


func add_source(src: Emitter) -> void:
	if not src in light_sources:
		light_sources.append(src)


func remove_source(src: Emitter) -> void:
	assert(src in light_sources)
	light_sources.erase(src)


func src_colors() -> Color:
	var col := Color.BLACK
	for em in light_sources:
		col += em.color
	return col.clamp()


# player raycast inrteract
var _on_the_move := false
func on_interaction() -> void:
	if _on_the_move:
		return
	#print("movalbe: ", movable)
	if not movable:
		return
	var move_dir := Math.dir_from_rot(get_tree().get_first_node_in_group("players").global_position.angle_to_point(global_position))
	_q_params.transform = Transform2D(0, global_position + Math.vec_from_dir(move_dir) * 16)
	#prints("i wanna go to", PlayerOverworld.Rots.find_key(move_dir), _q_params.transform.origin)
	var resulds := get_viewport().world_2d.direct_space_state.intersect_shape(_q_params)
	#print(resulds)
	if resulds.is_empty() or resulds.all(func(a: Dictionary) -> bool: return a["collider"] == self):
		_on_the_move = true
		SND.play_sound(preload("res://sounds/gui/rock_slide.tres"), {volume = 10, pitch_scale = 0.65, bus = "ECHO"})
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, ^"global_position", _q_params.transform.origin, 0.33)
		tw.tween_callback(func() -> void: _on_the_move = false)
