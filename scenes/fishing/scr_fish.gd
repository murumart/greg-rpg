class_name FishingFish extends Node2D

const FISH_TEXTURE_PATH := "res://sprites/fishing/spr_fish%s.png"

var yspeed := 60
var speed := randf_range(30, 90)
var moving := true
var ymoving := true
var direction := randi() % 2
var decor := false
@export var hazardous := false

@export var is_fish := true

var depth := 0
var value := 0

@onready var sprite := $Sprite


func _ready() -> void:
	sprite.flip_h = bool(direction)
	if sprite.material:
		sprite.material = sprite.material.duplicate(true)
		sprite.material["shader_parameter/speed"] = speed * 0.08
	assign_value()


func _physics_process(delta: float) -> void:
	if moving:
		if ymoving: global_position.y -= yspeed * delta
		global_position.x += speed * delta * (1 if direction else -1)
		if global_position.y < -66: queue_free()
		if absi(roundi(global_position.x)) > 88: queue_free()


func caught() -> void:
	moving = false
	$CatchAnimation.play("catch")


func _on_wall_hit(_body: Node2D) -> void:
	if decor: return
	direction = int(not bool(direction))
	sprite.flip_h = bool(direction)


func assign_value() -> void:
	var rarity := str(((randi() % maxi(depth, 1)) + depth) / float(depth)).count("8")
	value = mini(roundi(pow(2, rarity / 2.0)), 11)
	if !is_fish: return
	if FileAccess.file_exists(FISH_TEXTURE_PATH % (rarity + 1)):
		sprite.texture = load(FISH_TEXTURE_PATH % (rarity + 1))


func explode() -> void:
	SOL.vfx("explosion", self.global_position)

