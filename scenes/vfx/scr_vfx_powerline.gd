@tool
class_name VfxPowerline extends Node2D
## A visual electric spark-line type effect.
## Uses an animated [Line2D] with a gradent texture.
##

var __ready := false
var _getline: Line2D:
	get:
		return get_node("Line2D") as Line2D
@export var divisions := 10: ## Into how many sections the line is divided.
	set(to):
		divisions = maxi(2, to)
		if not __ready and not Engine.is_editor_hint():
			return
		_getline.clear_points()
		for p in divisions:
			_getline.add_point(Vector2())
		update_display()
## How far away each point can move every time it updates.
@export var deviation_distance := 2.0
## Delay between updates.
@export var delay := 0.05
var _delay := 0.0
## Width of the line, in pixels?
@export var line_width := 2.0:
	set(to):
		line_width = to
		if not __ready and not Engine.is_editor_hint():
			return
		_getline.width = to
## The visual gradient the line uses.
@export var gradient := Gradient.new()
## The line.
@onready var line := _getline as Line2D
## The line's start position.
@onready var start: Marker2D = $Start
## The line's end position.
@onready var end: Marker2D = $End
## How long for should the node exist (in seconds).
@export var lifetime := 0.0
var _lifetime := 0.0


func _ready() -> void:
	__ready = true

## This is called by the [code]SOL.vfx()[/code] function.
## It can initialise the start and end positions, and the node's lifetime.
func init(options := {}) -> void:
	#start.global_position = options.get("start_position", start.global_position)
	#end.global_position = options.get("end_position", end.global_position)
	lifetime = options.get("lifetime", lifetime)


func _physics_process(delta: float) -> void:
	_lifetime += delta
	if not is_visible_in_tree():
		return
	_delay += delta
	if _delay >= delay:
		update_display()
		wobble()
		_delay = 0.0
	if (lifetime != 0.0 and _lifetime >= lifetime) and not Engine.is_editor_hint():
		queue_free()

## Moves the line's points to proper positions.
## Also sets the gradient texture. Called in [code]_physics_process[/code].
func update_display() -> void:
	if Engine.is_editor_hint():
		line = _getline
	for p in divisions:
		line.points[p] = start.position.lerp(
				end.position, float(p) / (divisions - 1))
	line.texture.gradient = gradient

## Deviates the line's points' positions. Called in [code]_physics_process[/code].
func wobble() -> void:
	for p in divisions - 2:
		line.points[p + 1] += Vector2.from_angle(randf_range(-PI, PI)) * deviation_distance
