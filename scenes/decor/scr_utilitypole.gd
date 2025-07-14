@tool
extends Node2D

const Powerline = preload("res://scenes/decor/scr_utilitypole.gd")

const POINTS := 16
const LINES := 2

@export var draw_target: Powerline
@export var drawer: CanvasItem


func _ready() -> void:
	if not draw_target:
		set_physics_process(false)
		return
	drawer.draw.connect(func() -> void:
		draw_droopy_line(
			Vector2.ZERO,
			drawer.to_local(draw_target.drawer.global_position), 0.5)
	)
	if not Engine.is_editor_hint():
		set_physics_process(false)
		drawer.queue_redraw()


#func _draw() -> void:
	#draw_droopy_line(Vector2.ZERO, to_local(get_global_mouse_position()), 1.0)
#
#
#func _physics_process(_delta: float) -> void:
	#drawer.queue_redraw()


func draw_droopy_line(from: Vector2, to: Vector2, droopiness: float) -> void:
	var pts := PackedVector2Array()
	pts.resize(POINTS)
	var x := (POINTS / 2) ** 2 * droopiness
	for p in POINTS:
		var t := p / float(POINTS)
		pts[p] = from + (to - from) * t
	pts.append(to)
	for p in pts.size():
		pts[p].y =  pts[p].y - (p - POINTS / 2)**2 * droopiness + x
	drawer.draw_polyline(pts, Color.BLACK)
	for p in pts.size():
		pts[p].y += 6
	drawer.draw_polyline(pts, Color.BLACK)
