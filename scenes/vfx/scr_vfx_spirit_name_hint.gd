extends Node2D

var move := Vector2()
var clamp_zone_min := Vector2(10, 30)
var clamp_zone_max := Vector2()
var gravity := 0.8

var agit := 1.0

@onready var sprite := $Sprite
@onready var label := $Label
@onready var particles := $GPUParticles2D
const FRAMES_PATH := "res://scenes/vfx/sfr_spirit_%s.tres"

func _ready() -> void:
	clamp_zone_max = Vector2(SOL.SCREEN_SIZE.x - 10, SOL.SCREEN_SIZE.y / 2.0)
	position.x = randf_range(clamp_zone_min.x, clamp_zone_max.x)
	position.y = randf_range(clamp_zone_min.y, clamp_zone_max.y)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, randf_range(3.0, 12.0))
	sprite.play()


func init(options := {}) -> void:
	var srt: String = options.get("spirit", "unknown")
	if DIR.spirit_hint_exists(srt):
		sprite.sprite_frames = load(FRAMES_PATH % srt)
	var nam := ResMan.get_spirit(srt).name
	label.text = nam
	var h := str(hash(nam)).split()
	var g := []
	for i in h:
		g.append(float(i) / 10.0)
	particles.modulate = Color(g[0], g[1], g[2])
	sprite.play()


func _physics_process(delta: float) -> void:
	gravity = sin(Engine.get_physics_frames() / 100.0) * gravity
	
	if randf() < 0.02:
		move += Vector2(randf_range(-agit, agit), randf_range(-agit, agit))
		var tw1 := create_tween()
		tw1.tween_property(sprite, "modulate:a", randf_range(0.1, 1.1), randf_range(0.1, 2.0))
		var tw2 := create_tween()
		tw2.tween_property(label, "modulate:a", randf_range(0.3, 1.1), randf_range(0.1, 2.0))
	
	move.y = move_toward(move.y, 0.0, delta)
	move.x = move_toward(move.x, 0.0, delta)
	
	move.y += gravity
	
	move = move.limit_length(2.0)
	
	position += move
	if (position.x <= clamp_zone_min.x or position.x >= clamp_zone_max.x): move.x = -move.x
	if (position.y <= clamp_zone_min.y or position.y >= clamp_zone_max.y): move.y = -move.y
	position = position.clamp(clamp_zone_min, clamp_zone_max)


func del() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.0)
	tw.finished.connect(queue_free)

