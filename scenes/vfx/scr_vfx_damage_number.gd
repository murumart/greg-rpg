extends Node2D

# damage number vfx

var move := Vector2()
var gravity := 80
var xrange := 1.0
var clamp_zone_min := Vector2(10, 0)
var clamp_zone_max := Vector2()


func init(options := {}) -> void:
	var label := $Label
	var size: float = options.get("size", 1.0) # font size in multiples of 8
	label.text = str(options.get("text", ""))
	gravity = int(options.get("gravity", 80))
	label.modulate = options.get("color", Color.WHITE)
	label["theme_override_font_sizes/font_size"] = 8 * size
	clamp_zone_max = Vector2(SOL.SCREEN_SIZE.x - 10, SOL.SCREEN_SIZE.y - 10)
	move.x += randf_range(-xrange, xrange) * size
	move.y -= randf_range(0.3, 0.6) * size
	$AnimationPlayer.speed_scale = options.get("speed", 1.0)


func _ready() -> void:
	pass


# movement physics
func _physics_process(delta: float) -> void:
	move.y = move_toward(move.y, gravity, delta * 2)
	move.x = move_toward(move.x, 0.0, delta * 1.5)

	position += move
	if (position.x <= clamp_zone_min.x or position.x >= clamp_zone_max.x): move.x = -move.x
	if (position.y <= clamp_zone_min.y or position.y >= clamp_zone_max.y): move.y = -move.y
	position = position.clamp(clamp_zone_min, clamp_zone_max)
