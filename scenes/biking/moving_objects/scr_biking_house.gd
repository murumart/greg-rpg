extends BikingMovingObject

const HOUSE_COUNT := 6

@onready var sprite := $Sprite2D


func _ready() -> void:
	add_to_group("biking_houses")
	sprite.region_rect.position.x = randi() % HOUSE_COUNT * 48
	sprite.flip_h = int(randi() % 2)


func set_snail(to: bool) -> void:
	sprite.visible = not to
	$SNAIL.visible = to

