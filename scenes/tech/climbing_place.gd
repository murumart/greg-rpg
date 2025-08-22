extends Area2D

signal started_climbing
signal started_falling
signal stopped_climbing

enum States {
	NOTHING,
	CLIMBING,
	HALTED,
	FALLING,
}

@onready var greg_climp: Node2D = $GregClimp
@onready var greg_climp_sprite: Sprite2D = $GregClimp/GregClimpSprite
@onready var climp_sound: AudioStreamPlayer = $GregClimp/GregClimpSprite/ClimpSound
@onready var contact: Area2D = $GregClimp/Contact

@export var ground_levels: Array[Area2D]
@export var ground_level_y: int
@export var greg: PlayerOverworld
@export var camera: Camera2D
@export var grace_time := 0.04
@export var greg_speed := 60.0
@export_range(0, 24) var initial_height: int = 8

var state: States:
	set(to): print("state is " + States.find_key(to)); state = to
var _w := 0.0
var _grace := 0.0
var _no_getoff_grace := 0.0


func _physics_process(delta: float) -> void:
	if state == States.CLIMBING and not LTS.transitioning:

		if _w <= 0:
			climp_sound.play()
			greg_climp_sprite.flip_h = not greg_climp_sprite.flip_h
			_w = 0.07
		var climp_mov := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		if climp_mov:
			_w -= delta
		greg_climp.position += climp_mov * greg_speed * delta
		_no_getoff_grace -= delta

		var ars := contact.get_overlapping_areas()
		for g in ground_levels:
			if g in ars:
				if _no_getoff_grace <= 0:
					cease_climping(g.global_position)
		if not ars and not contact.has_overlapping_bodies():
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
	#if camera:
		#var gps := camera.global_position
		#greg_climp.remove_child(camera)
		#add_child(camera)
		#camera.global_position = gps
	if state == States.FALLING:
		return # dont tumble multipe times..
	started_falling.emit()
	state = States.FALLING
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	var dist := ground_level_y - greg_climp.global_position.y
	tw.tween_property(greg_climp, ^"global_position:y", ground_level_y, dist / 70.0)
	tw.parallel().set_ease(Tween.EASE_OUT).tween_property(greg_climp, ^"rotation", TAU * remap(dist, 0, 32, 0, 2), dist / 70.0)
	tw.tween_callback(func() -> void:
		SOL.shake(.5)
		cease_climping()
		SND.play_sound(preload("res://sounds/bump.ogg"), {volume = -4})
	)


func begin_climping() -> void:
	for x: Area2D in get_tree().get_nodes_in_group(&"sg_climbing_obstacle"):
		if x.has_connections("area_entered"): continue
		x.area_entered.connect(_tumble.unbind(1))
	started_climbing.emit()
	_no_getoff_grace = 0.8
	DAT.capture_player("climp")
	greg.hide()
	if camera:
		greg.remove_child(camera)
		greg_climp.add_child(camera)
		camera.position = Vector2(0, 0)
	greg_climp.show()
	greg_climp.rotation = 0
	SND.play_sound(preload("res://sounds/skating/s2.ogg"))
	greg_climp.global_position = greg.global_position + Vector2(0, -initial_height)
	state = States.CLIMBING
	contact.force_update_transform()


func cease_climping(stop_pos := greg_climp.global_position) -> void:
	stopped_climbing.emit()
	greg.show()
	if camera:
		camera.get_parent().remove_child(camera)
		greg.add_child(camera)
		camera.position = Vector2(0, -9)
	DAT.free_player("climp")
	greg_climp.hide()
	state = States.NOTHING
	greg.global_position = stop_pos + Vector2(0, 8)
