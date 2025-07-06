extends Node2D

const Powerline = preload("res://scenes/decor/scr_utilitypole.gd")

const POINTS := 16

@export var draw_target: Powerline


func _ready() -> void:
	if not draw_target:
		return
	draw.connect(func() -> void:
		draw_droopy_line(Vector2.ZERO, to_local(draw_target.global_position), 1.0)
	)


#func _draw() -> void:
	#draw_droopy_line(Vector2.ZERO, to_local(get_global_mouse_position()), 1.0)
#
#
#func _physics_process(delta: float) -> void:
	#queue_redraw()


func draw_droopy_line(from: Vector2, to: Vector2, droopiness: float) -> void:
	var pts := PackedVector2Array()
	pts.resize(POINTS)
	for p in POINTS:
		var dist := float(p) / float(POINTS)
		pts[p] = from.lerp(to, dist)
	draw_polyline(pts, Color.BLACK)
