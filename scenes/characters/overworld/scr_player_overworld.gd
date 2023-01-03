extends CharacterBody2D
class_name PlayerOverworld

const SPEED := 2600

var input := Vector2()


func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	velocity = Vector2()
	
	velocity = input * SPEED * delta
	
	var _collided := move_and_slide()
	
	global_position.x = roundi(global_position.x)
	global_position.y = roundi(global_position.y)

