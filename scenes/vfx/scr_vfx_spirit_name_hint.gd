extends Node2D

const FRAMES_PATH := "res://scenes/vfx/sfr_spirit_%s.tres"
const SPRITE_PATH := "res://sprites/spirit/spr_%s_hint.png"

var move := Vector2()
var clamp_zone_min := Vector2(10, 30)
var clamp_zone_max := Vector2()
var gravity := 0.8
var display_mode := 0

var agit := 1.0

static var sprite_frame_storage := {}

@onready var sprite := $Sprite as AnimatedSprite2D
@onready var label := $Label
@onready var particles := $GPUParticles2D
@onready var timer: Timer = $Timer


func _ready() -> void:
	clamp_zone_max = Vector2(SOL.SCREEN_SIZE.x - 10, SOL.SCREEN_SIZE.y / 2.0)
	position.x = randf_range(clamp_zone_min.x, clamp_zone_max.x)
	position.y = randf_range(clamp_zone_min.y, clamp_zone_max.y)
	modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, randf_range(3.0, 12.0))
	sprite.play()


func init(options := {}) -> void:
	var spirit_name := options.get("spirit", "unknown") as String
	if ResourceLoader.exists(FRAMES_PATH % spirit_name):
		sprite.sprite_frames = load(FRAMES_PATH % spirit_name)
	elif ResourceLoader.exists(SPRITE_PATH % spirit_name):
		sprite.sprite_frames = _sprite_frames_from_file(SPRITE_PATH % spirit_name)
	# else: use default
	var nam := ResMan.get_spirit(spirit_name).name
	var cost := ResMan.get_spirit(spirit_name).cost
	label.text = nam
	var h := str(hash(nam)).split()
	var g := []
	for i in h:
		g.append(float(i) * 0.01)
	particles.modulate = Color(g[0], g[1], g[2])
	sprite.play()
	timer.wait_time = maxf(randfn(3.0, 1.0), 0.2)
	timer.timeout.connect(func():
		if display_mode == 0:
			display_mode = 1
			label.text = str(cost)
			label.modulate = Color.DODGER_BLUE
		elif display_mode == 1:
			display_mode = 0
			label.text = nam
			label.modulate = Color.WHITE
	)


func _physics_process(delta: float) -> void:
	gravity = sin(Engine.get_physics_frames() * 0.01) * gravity

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
	if (position.x <= clamp_zone_min.x or position.x >= clamp_zone_max.x):
		move.x = -move.x
	if (position.y <= clamp_zone_min.y or position.y >= clamp_zone_max.y):
		move.y = -move.y
	position = position.clamp(clamp_zone_min, clamp_zone_max)


func del() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.0)
	tw.finished.connect(queue_free)


func _sprite_frames_from_file(sprite_path: String) -> SpriteFrames:
	if sprite_path in sprite_frame_storage.keys():
		return sprite_frame_storage[sprite_path]
	var frames = SpriteFrames.new()
	var texture := load(sprite_path) as CompressedTexture2D
	print(load(sprite_path))
	const WIDTH = 16
	var hframes = texture.get_height() / WIDTH
	for i in hframes:
		var at := AtlasTexture.new()
		at.atlas = texture
		at.region = Rect2(0, WIDTH * i, WIDTH, WIDTH)
		frames.add_frame("default", at)
	sprite_frame_storage[sprite_path] = frames
	return frames
