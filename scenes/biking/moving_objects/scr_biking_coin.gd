extends BikingMovingObject

@onready var collection_area: Area2D = $Area2D


func _ready() -> void:
	collection_area.area_entered.connect(func(_a):
		coin_got.emit()
		queue_free()
	)
