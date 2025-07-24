extends Area2D

enum States {
	NOTHING,
	CLIMBING,
	FALLING,
}

@onready var greg_climp: Node2D = $GregClimp
@onready var greg_climp_sprite: Sprite2D = $GregClimp/GregClimpSprite
@onready var climp_sound: AudioStreamPlayer = $GregClimp/GregClimpSprite/ClimpSound
@onready var contact: Area2D = $GregClimp/Contact

@export var ground_levels: Array[Area2D]
@export var ground_level_y: int
@export var greg: PlayerOverworld
@export var grace_time := 0.04

var state: States:
	set(to): print("state is " + States.find_key(to)); state = to
var _w := 0.0
var _grace := 0.0


func _physics_process(delta: float) -> void:
	if state == States.CLIMBING:

		if _w <= 0:
			climp_sound.play()
			greg_climp_sprite.flip_h = not greg_climp_sprite.flip_h
			_w = 0.07
		var climp_mov := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		if climp_mov:
			_w -= delta
		greg_climp.position += climp_mov * 60.0 * delta

		print(contact.get_overlapping_areas())
		if not contact.has_overlapping_areas():
			if _grace < 0:
				SND.play_sound(preload("res://sounds/skating/s9.ogg"))
				_tumble()
				_grace = grace_time
			else:
				_grace -= delta
		else:
			_grace = grace_time
			if greg_climp.global_position.y >= ground_level_y:
				cease_climping()



func _tumble() -> void:
	state = States.FALLING
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	var dist := ground_level_y - greg_climp.global_position.y
	tw.tween_property(greg_climp, ^"global_position:y", ground_level_y, dist / 70.0)
	tw.parallel().set_ease(Tween.EASE_OUT).tween_property(greg_climp, ^"rotation", TAU * remap(dist, 0, 32, 0, 2), dist / 70.0)
	tw.tween_callback(func() -> void:
		SOL.shake(.5)
		cease_climping()
		SND.play_sound(preload("res://sounds/bump.ogg"))
	)


func begin_climping() -> void:
	DAT.capture_player("climp")
	greg.hide()
	greg_climp.show()
	greg_climp.rotation = 0
	SND.play_sound(preload("res://sounds/skating/s2.ogg"))
	greg_climp.global_position = greg.global_position + Vector2(0, -16)
	state = States.CLIMBING
	contact.force_update_transform()


func cease_climping() -> void:
	greg.show()
	DAT.free_player("climp")
	greg_climp.hide()
	state = States.NOTHING
	greg.global_position = greg_climp.global_position + Vector2(0, 8)
