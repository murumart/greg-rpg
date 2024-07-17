extends Node2D

@onready var grandma: OverworldCharacter = $"../InteriorTiles/Grandma/Grandma"
@onready var greg: PlayerOverworld = $"../Greg"
@onready var tilemap: TileMap = $"../InteriorTiles"
@onready var gregpos: Vector2 = $Gregpos.global_position
@onready var gregpos2: Vector2 = $Gregpos2.global_position
@onready var grandmapos: Vector2 = $Grandmapos.global_position
@onready var lamp: PointLight2D = $"../Greenhouse/Lamp"
@onready var aah: AudioStreamPlayer2D = $AAh
@onready var color_container: ColorContainer = $"../CanvasModulateGroup/ColorContainer"
@onready var stairs: Sprite2D = $Stairs
@onready var walking: AudioStreamPlayer = $Walking
var walk_timer := Timer.new()
@onready var picture: Sprite2D = $Picture


func _ready() -> void:
	add_child(walk_timer)
	walk_timer.timeout.connect(_walk_sound)


func play() -> void:
	SOL.dialogue_box.add_dialogue_string(DIALOGUE)
	DAT.capture_player("cutscene")
	tilemap.set_layer_enabled(1, false)
	greg.global_position = gregpos
	grandma.global_position = grandmapos
	greg.animate("walk_up", false)
	await Math.timer(1.0)
	SND.play_song("byddd")
	SOL.dialogue("end_1")
	SOL.dialogue_box.started_speaking.connect(_line_start)
	await SOL.dialogue_closed
	SOL.dialogue_box.started_speaking.disconnect(_line_start)
	await Math.timer(1.5)
	SOL.dialogue("end_2")
	await SOL.dialogue_closed
	SND.play_song("", 99)
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	var lampfinal := (grandma.global_position - lamp.global_position) * 2
	remove_child(aah)
	lamp.add_child(aah)
	aah.position = Vector2.ZERO
	aah.playing = true
	tw.tween_property(lamp, "global_position", lampfinal, 3.0)
	tw.parallel().tween_property(grandma,
			"modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN).set_delay(1.0)
	await tw.finished
	await Math.timer(0.8)
	SND.play_song("bymsps", 0.2)
	greg.set_collision_mask_value(1, false)
	greg.animate("walk_up", true, 0.33)
	walk_timer.start(0.606060)
	aah.playing = false
	tw = create_tween()
	tw.tween_property(greg, "global_position:y", gregpos2.y, 10.0)
	tw.parallel().tween_property(tilemap, "modulate:a", 0.0, 5.0)
	tw.parallel().tween_property(stairs, "modulate:a", 1.0, 5.0).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(color_container, "color", Color.LIGHT_SALMON, 8.0)
	await tw.finished
	greg.animate("walk_up")
	walk_timer.stop()
	await Math.timer(2.0)
	greg.animate("walk_down")
	await Math.timer(0.8)
	tw = create_tween()
	tw.tween_property(greg, "global_position:y", gregpos2.y - 3.0, 0.4)
	walking.play()
	await Math.timer(2.0)
	remove_child(picture)
	SOL.add_ui_child(picture)
	picture.show()
	tw = create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(picture.material, "shader_parameter/modulate",
			Color.WHITE, 2.0).from(Color.BLACK)
	tw.tween_callback(func(): SOL.dialogue("end_3"))
	await SOL.dialogue_closed
	await Math.timer(2.0)
	tw = create_tween()
	tw.tween_property(picture.material, "shader_parameter/amount",
			4.0, 15.0)
	var e: Array = DIR.gej(3, [])
	e.append(1)
	DIR.sej(3, e)
	await Math.timer(8.0)
	LTS.level_transition("res://scenes/gui/scn_end_credits.tscn")


func _line_start(line: int) -> void:
	print(line)
	if line == 3:
		var tw := create_tween()
		tw.tween_property(
				grandma, "global_position", grandma.global_position - Vector2(0, 12), 0.2)
		grandma.direct_walking_animation(Vector2.DOWN)
		SND.play_song("", 99)
	elif line == 4:
		SND.play_song("shitty_entrance_of_the_gladiators", 0.1)
	elif line == 7:
		grandma.direct_walking_animation(Vector2.LEFT)
		await Math.timer(0.65)
		grandma.direct_walking_animation(Vector2.RIGHT)
		await Math.timer(0.65)
		grandma.direct_walking_animation(Vector2.UP)
		await Math.timer(0.65)
		grandma.direct_walking_animation(Vector2.DOWN)
	elif line == 8:
		grandma.movement_wait = 0.5
		grandma.random_movement = true
		grandma.random_movement_timer.start(0.5)
		grandma.random_movement_distance = 12
	elif line == 10:
		grandma.direct_walking_animation(greg.global_position - grandma.global_position)
		grandma.random_movement = false
		grandma.speed = 0
		grandma.set_deferred("speed", 3500)


func _walk_sound() -> void:
	walking.play()
	walk_timer.start(1.21212)


const DIALOGUE := "

DIALOGUE end_1
CHAR grandma
	okay... okay... i get it... i see now...
	you're strong enough to take back your house...
INSTASKIP
	you're strong enough... you can
CHAR greg
	that's right █████!!! i demolished you right now
CHAR grandma
	...excuse me?
CHAR greg
	get outta my house
	leave the ██████ house nooooooow!
CHAR grandma
	i... uh... um...
CHAR greg
	get out! hup hup hup!
CHAR grandma
	i... my hip... i'm pretty sure it's broken...
CHAR greg
	████████████ ██████ the ███████████ ████
CHAR grandma
	okay okay i get it... bye... good grief...


DIALOGUE end_2
CHAR grandma
	where's the exit...
CHAR greg
	right there.


DIALOGUE end_3
CHAR greg
	now i must sit and ponder for a thousand years.

"
