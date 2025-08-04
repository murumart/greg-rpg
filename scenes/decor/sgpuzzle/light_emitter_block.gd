extends "res://scenes/decor/sgpuzzle/light_receiver_block.gd"
const CATCHER_LAYER = 10

const Dir = PlayerOverworld.Rots
enum Role {EMITTER, REDIRECTOR}

@onready var cast: RayCast2D = %Cast
@onready var light: Sprite2D = %Light
@onready var light_2: Sprite2D = %Light2
@onready var base: Sprite2D = $Base
@onready var top: Sprite2D = $Top
@onready var alight: AudioStreamPlayer2D = $Alight
@onready var unlight: AudioStreamPlayer2D = $Unlight

@export_color_no_alpha var my_color := Color.WHITE
@export var emitting := true:
	set(to):
		emitting = to
		%Light.visible = to
@export var direction: Dir
@export var role: Role = Role.EMITTER

var _is_ready := false


func _ready() -> void:
	super()
	_is_ready = true
	set_direction(direction)
	light.modulate = my_color
	light_2.modulate = my_color
	base.region_rect.position.y = 80 - int(movable) * 16
	base.region_rect.position.x = [0, 1, 2, 3][direction] * 16
	top.region_rect.position.x = 64 + role * 16
	#emitting = emitting


var _last_hit: StaticBody2D
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var tget := cast.get_collider()
	if not is_instance_valid(tget) or not emitting:
		if is_instance_valid(_last_hit):
			_last_hit.remove_source(self)
			_last_hit = null
		return
	if not emitting:
		return
	if tget != _last_hit:
		if is_instance_valid(_last_hit):
			_last_hit.remove_source(self)
			_last_hit = null
	if tget is Receiver:
		tget.add_source(self)
		_last_hit = tget
	light.scale.y = (global_position.distance_to(cast.get_collision_point()) + 8) * 0.0625


func add_source(src: Emitter) -> void:
	var os := light_sources.size()
	super(src)
	if role == Role.REDIRECTOR:
		color = (my_color + src_colors()).clamp()
		emitting = color != Color.BLACK
		if emitting and os != light_sources.size(): alight.play()
		light.modulate = color


func remove_source(src: Emitter) -> void:
	var os := light_sources.size()
	super(src)
	if role == Role.REDIRECTOR:
		color = (my_color + src_colors()).clamp()
		emitting = src_colors() != Color.BLACK
		if not emitting and os != light_sources.size(): unlight.play()
		light.modulate = color


func set_direction(to: Dir) -> void:
	if not _is_ready:
		return
	direction = to
	match direction:
		Dir.UP:
			$Light.rotation = 0
			$Cast.target_position = Vector2(0, -512)
		Dir.LEFT:
			%Light.rotation = -PI * 0.5
			%Cast.target_position = Vector2(-512, 0)
		Dir.DOWN:
			%Light.rotation = PI
			%Cast.target_position = Vector2(0, 512)
		Dir.RIGHT:
			%Light.rotation = PI * 0.5
			%Cast.target_position = Vector2(512, 0)
