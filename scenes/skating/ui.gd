extends Control

const POINTER_RANGE := Vector2i(3, 44)

@onready var balance_pointer: Sprite2D = $Panel/Balance/Pointer
@onready var boredom_pointer: Sprite2D = $Panel/Boredom/Pointer


func display_balance(balance: float) -> void:
	balance_pointer.position.x = remap(balance, -1.0, 1.0, POINTER_RANGE.x, POINTER_RANGE.y)


func display_boredom(boredom: float) -> void:
	boredom_pointer.position.x = remap(maxf(boredom, 0.0), 0.0, 10.0, POINTER_RANGE.x, POINTER_RANGE.y)

