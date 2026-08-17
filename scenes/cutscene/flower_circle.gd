extends Node2D

var found := 0

@export var distance := 24.0


func _ready() -> void:
	for i in 7:
		var angle := Vector2.from_angle(TAU * (i / 7.0))
		flower(i).position = angle * distance
		var particles := GPUParticles2D.new()
		flower(i).add_child(particles)
		particles.process_material = preload("res://resources/ppm_power.tres")
		particles.texture = flower(i).texture
		particles.modulate.a = 0.1
		particles.material = preload("res://resources/add_material.tres")
		particles.show_behind_parent = true


var _d := 0.0
func _process(delta: float) -> void:
	_d += delta
	rotation = sin(_d * 0.5 * (1 + found * 0.2)) * found * 0.125
	for i in 7:
		flower(i).global_rotation = 0
		flower(i).position.y += sin(_d * 2.0 + i * 0.1) * delta * found * 1.5


func flower(i: int) -> Sprite2D:
	var f := get_child(i) as Sprite2D
	assert(f)
	return f


func show_cool() -> void:
	var i := 0
	for c: Sprite2D in get_children():
		c.modulate.a = 0.0
		var ft := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		ft.tween_interval(i * 0.12)
		ft.tween_callback(SND.play_sound.bind(preload("res://sounds/sg/alight.ogg"), {"pitch_scale": 0.75 * (1 + i * 0.25)}))
		ft.tween_property(c, ^"scale", Vector2.ONE, 0.3).from(Vector2.ONE * 4)
		ft.parallel().tween_property(c, ^"modulate:a", 1.0, 0.3)
		i += 1
