extends OverworldCharacter

enum {HEAD, BODY, RIGHT_ARM, LEFT_ARM, LEGS, MAX}

const V2M1 := Vector2.ONE * -1

@onready var body: AnimatedSprite2D = $Body/Body/Body
@onready var legs: AnimatedSprite2D = $Body/Legs/Legs
@onready var right_arm: AnimatedSprite2D = $Body/RightArm/RightArm
@onready var left_arm: AnimatedSprite2D = $Body/LeftArm/LeftArm
@onready var head: AnimatedSprite2D = $Body/Head/Head

var bodyparts: Array[AnimatedSprite2D]

var times: PackedFloat32Array
@export var speeds: PackedFloat32Array
@export var mov_sizes: PackedVector2Array


func _ready() -> void:
	bodyparts = [head, body, right_arm, left_arm, legs]
	times.resize(MAX)
	speeds.resize(MAX)
	mov_sizes.resize(MAX)
	if not Engine.is_editor_hint():
		super()


func _physics_process(delta: float) -> void:
	for i in MAX:
		var b := bodyparts[i]
		b.position.x = sin(times[i]) * mov_sizes[i].x
		b.position.y = cos(times[i]) * mov_sizes[i].y
		times[i] += delta * speeds[i]
	if not Engine.is_editor_hint():
		super(delta)


func animate(
	bpart: int,
	anim: StringName,
	argspeed: float = -1.0,
	mov_size := V2M1,
	aspeed: float = -1.0,
	flip := false
) -> void:
	assert(bpart >= 0 and bpart < MAX)
	var b := bodyparts[bpart]
	b.play(anim, aspeed if aspeed != -1.0 else 1.0)
	b.flip_h = flip
	speeds[bpart] = argspeed if argspeed != -1.0 else speeds[bpart]
	mov_sizes[bpart] = mov_size if mov_size != V2M1 else mov_sizes[bpart]


func a_leg(anim: StringName, anspd := 1.0, mov_size := V2M1, arspd := -1.0, flip := false) -> void:
	animate(LEGS, anim, arspd, mov_size, anspd, flip)


func a_rarm(anim: StringName, anspd := 1.0, mov_size := V2M1, arspd := -1.0, flip := false) -> void:
	animate(RIGHT_ARM, anim, arspd, mov_size, anspd, flip)


func a_larm(anim: StringName, anspd := 1.0, mov_size := V2M1, arspd := -1.0, flip := false) -> void:
	animate(LEFT_ARM, anim, arspd, mov_size, anspd, flip)


func a_default() -> void:
	a_larm("hip")
	a_rarm("hip")
	a_leg("default")
	animate(HEAD, "default")
