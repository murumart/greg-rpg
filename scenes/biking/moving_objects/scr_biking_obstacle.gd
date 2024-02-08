class_name BikingObstacle extends BikingMovingObject

@export var area: Area2D
@export var damage: int = 25


func _init() -> void:
	super()
	add_to_group("biking_obstacles")
