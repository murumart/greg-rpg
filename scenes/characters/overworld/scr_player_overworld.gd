extends CharacterBody2D
class_name PlayerOverworld

const SPEED := 3000
const FRICTION := 720

var input := Vector2()


func _physics_process(delta: float) -> void:
	input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * delta * SPEED
	
	velocity = Vector2()
	velocity = input.normalized() * delta * SPEED
	
	var _collided := move_and_slide()
	
	global_position.x = roundi(global_position.x)
	global_position.y = roundi(global_position.y)

