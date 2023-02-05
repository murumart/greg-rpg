extends Node2D

var move := Vector2()
var gravity := 10
var xrange := 0.8


func init(options := {}) -> void:
	var label := $Label
	var size : float = options.get("size", 1.0)
	label.text = str(options.get("text", ""))
	label.modulate = options.get("color", Color.WHITE)
	label["theme_override_font_sizes/font_size"] = 8 * size
	move.x += randf_range(-xrange, xrange) * size
	move.y -= randf_range(0.2, 0.4) * size
	$AnimationPlayer.speed_scale = options.get("speed", 1.0)


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	move.y = move_toward(move.y, gravity, delta)
	move.x = move_toward(move.x, 0.0, delta * 2)
	
	position += move
	position = position.clamp(Vector2(10, 0), Vector2(SOL.SCREEN_SIZE.x - 10, 188))
