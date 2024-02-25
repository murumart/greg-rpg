extends Node2D

@export var spin_speed := 155
@onready var beam := $Lighthouse/Beam as Sprite2D
var beam_direction := 1.0
@onready var mus_bar_counter: MusBarCounter = $MusBarCounter
@onready var spin_pivot: Node2D = $Lighthouse/SpinPivot


func _ready() -> void:
	mus_bar_counter.new_beat.connect(func(): pass)


func _physics_process(delta: float) -> void:
	beam.scale.x += delta * spin_speed * (1 / 60.0) * beam_direction
	if beam.scale.x >= 2.0 or beam.scale.x <= -2.0:
		beam_direction *= -1
	beam.self_modulate.a = remap(absf(beam.scale.x), 0.0, 2.0, 0.1, 1.1)
	spin_pivot.rotation += spin_speed * delta * (1 / 60.0)
	spin_pivot.get_children().map(func(a: OverworldCharacter):
		a.global_rotation = 0.0
		a.direct_walking_animation(a.global_position.direction_to(spin_pivot.global_position))
	)
