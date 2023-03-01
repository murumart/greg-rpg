extends Control

@onready var road := $Road
@onready var pointer := $Pointer


func _ready() -> void:
	pass


func set_pointer_pos(percent: float) -> void:
	pointer.global_position.x = remap(percent, 0.0, 1.0, road.position.x, road.position.x + road.size.x)

