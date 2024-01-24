extends Control

const POINTER_RANGE := Vector2i(3, 44)

@onready var balance_pointer: Sprite2D = $Panel/Balance/Pointer


func display_balance(balance: float) -> void:
	balance_pointer.position.x = remap(balance, -1.0, 1.0, POINTER_RANGE.x, POINTER_RANGE.y)
