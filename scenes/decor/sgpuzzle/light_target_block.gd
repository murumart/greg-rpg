extends "res://scenes/decor/sgpuzzle/light_receiver_block.gd"

signal activated
signal deactivated

@onready var light: Sprite2D = %Light
@onready var base: Sprite2D = %Base
@onready var activation: Sprite2D = %Activation
@onready var target_sound: AudioStreamPlayer2D = $TargetSound
@onready var unlight: AudioStreamPlayer2D = $Unlight

var active := false



func _ready() -> void:
	light.modulate = color
	activation.modulate = color
	activation.hide()
	base.region_rect.position.x = int(movable) * 16


func add_source(src: Emitter) -> void:
	super(src)
	if src_colors() == color:
		_activate()
	else:
		_deactivate()


func remove_source(src: Emitter) -> void:
	super(src)
	if src_colors() == color:
		_activate()
	else:
		_deactivate()


func _activate() -> void:
	if not active:
		active = true
		activated.emit()
		activation.show()
		light.modulate = color * 2.0
		target_sound.play()


func _deactivate() -> void:
	active = false
	deactivated.emit()
	activation.hide()
	light.modulate = color
	unlight.play()
