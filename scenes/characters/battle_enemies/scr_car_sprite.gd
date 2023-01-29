extends Sprite2D


func _ready() -> void:
	modulate = DAT.A.get("last_hit_car_color", Color(1, 1, 1, 1))
