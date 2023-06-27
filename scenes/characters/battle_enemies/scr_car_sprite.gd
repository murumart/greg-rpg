extends Sprite2D

const PATH := "res://sprites/characters/battle/car/spr_car_battle_%s.png"

func _ready() -> void:
	modulate = DAT.get_data("last_hit_car_color", Color(1, 1, 1, 1))
	var nam := DAT.get_data("last_hit_car_name", "") as String
	var path := PATH % nam
	if ResourceLoader.exists(path):
		texture = load(path)
