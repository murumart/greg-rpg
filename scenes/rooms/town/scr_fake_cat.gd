extends Sprite2D


func _ready() -> void:
	if not Math.inrange(DAT.get_data("nr", 0.0), 0.67, 0.675):
		queue_free()
		return
	show()
