extends Node2D

var _done: bool:
	set(to): DAT.set_data("x_chase_done", to)
	get: return DAT.get_data("x_chase_done", false)

@onready var key: PickableItem = $Key


func _ready() -> void:
		if _done:
			$DoorArea/StaticBody2D/CollisionShape2D.disabled = true
		else:
			$DoorArea.hide()
			if is_instance_valid(key):
				key.queue_free()
