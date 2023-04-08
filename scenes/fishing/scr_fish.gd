class_name FishingFish extends Node2D

const FISH_TEXTURE_PATH := "res://sprites/fishing/spr_fish%s.png"

var yspeed := 60
var speed := randf_range(30, 90)
var moving := true
var direction := randi() % 2

var depth := 0
var value := 0

@onready var sprite := $Sprite2D


func _ready() -> void:
	sprite.flip_h = bool(direction)
	sprite.material["shader_parameter/speed"] = speed * 0.05
	assign_value()


func _physics_process(delta: float) -> void:
	if moving:
		global_position.y -= yspeed * delta
		global_position.x += speed * delta * (1 if direction else -1)
		if global_position.y < -66: queue_free()
		if absi(global_position.x) > 88: queue_free()


func _on_hook_area_hooked(_area: Area2D) -> void:
	pass


func _on_wall_hit(_body: Node2D) -> void:
	direction = int(not bool(direction))
	sprite.flip_h = bool(direction)


func assign_value() -> void:
	var rarity := str(((randi() % maxi(depth, 1)) + depth) / float(depth)).count("8")
	print(rarity)
	var value := roundi(pow(2, rarity / 2.0))
	if FileAccess.file_exists(FISH_TEXTURE_PATH % (rarity + 1)):
		sprite.texture = load(FISH_TEXTURE_PATH % (rarity + 1))

