extends "res://scenes/characters/battle_enemies/woods_guy_fight/rose_bullet.gd"

const BIRD_BULLET = preload("res://scenes/characters/battle_enemies/woods_guy_fight/bird_bullet.tscn")

@onready var line: Line2D = $Line
@onready var audio: AudioStreamPlayer = $WarningAudio
@onready var visual: Node2D = $ScnVfxBirdFlight


func _ready() -> void:
	line.points[1] = direction * 20
	create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC).tween_property(line, "modulate:a", 0.0, 4.0)
	audio.play()


func _physics_process(delta: float) -> void:
	super(delta)
	visual.rotation = direction.angle() + PI * 0.5


static func create_bird() -> RoseBullet:
	var rb := BIRD_BULLET.instantiate()
	return rb
