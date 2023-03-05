extends BikingMovingObject

const HOUSE_COUNT := 6

@onready var sprite := $Sprite2D


func _ready() -> void:
	sprite.region_rect.position.x = randi() % HOUSE_COUNT * 48
	sprite.flip_h = int(randi() % 2)

