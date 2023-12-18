class_name FishingFish extends Node2D

# also known as the swimmy ones

const FISH_TEXTURES := [
	preload("res://sprites/fishing/spr_fish1.png"),
	preload("res://sprites/fishing/spr_fish2.png"),
	preload("res://sprites/fishing/spr_fish3.png"),
	preload("res://sprites/fishing/spr_fish4.png"),
	preload("res://sprites/fishing/spr_fish5.png"),
	preload("res://sprites/fishing/spr_fish6.png"),
	preload("res://sprites/fishing/spr_fish7.png"),
]

var yspeed := 60
var speed := randf_range(30, 90)
var moving := true
var ymoving := true
var direction := randi() % 2
var decor := false
@export var hazardous := false

@export var is_fish := true
@export var item := &""

var depth := 0
var value := 0

@onready var sprite := $Sprite
@onready var hook_area: Area2D = $HookArea
@onready var wallrun_area: Area2D = $WallrunArea


func _ready() -> void:
	sprite.flip_h = bool(direction)
	assign_value()
	if sprite.material:
		# have to duplicate to make the wave animation speeds not be the same across all fish
		sprite.material = sprite.material.duplicate(false)
		sprite.material["shader_parameter/speed"] = speed * 0.08


func _physics_process(delta: float) -> void:
	if moving:
		if ymoving: global_position.y -= yspeed * delta
		global_position.x += speed * delta * (1 if direction else -1)
		if global_position.y < -66: queue_free()
		if absi(roundi(global_position.x)) > 88: queue_free()


func caught() -> void:
	moving = false
	$CatchAnimation.play("catch")


# bouncing
func _on_wall_hit(_body: Node2D) -> void:
	if decor: return
	direction = int(not bool(direction))
	sprite.flip_h = bool(direction)


func assign_value() -> void:
	if not is_fish:
		if item:
			sprite.texture = DAT.get_item(item).texture
			sprite.material = null
		return
	# hehehe
	var rarity := str(((randi() % maxi(depth, 1)) + depth) / float(depth)).count("8")
	value = mini(roundi(pow(2, rarity / 2.0)), 11)
	if rarity < FISH_TEXTURES.size():
		sprite.texture = FISH_TEXTURES[rarity]


func explode() -> void:
	SOL.vfx("explosion", self.global_position)

