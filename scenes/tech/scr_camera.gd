extends Camera2D

# screen shake variables
const SHAKE_DECAY := 0.8
const SHAKE_MAX_OFFSET := Vector2(100, 75)
const SHAKE_REDUCTION_CONSTANT := 0.2

var shake_trauma := 0.0
var shake_trauma_power := 2


func _ready() -> void:
	make_current()


func add_trauma(amount: float) -> void:
	shake_trauma = minf(shake_trauma + amount, 1.0)


func _physics_process(delta: float) -> void:
	shake_trauma = move_toward(shake_trauma, 0.0, SHAKE_DECAY * delta)
	
	var shake_amount := pow(shake_trauma, shake_trauma_power)
	offset.x = SHAKE_MAX_OFFSET.x * shake_amount * randf_range(-1.0, 1.0) * OPT.screen_shake_intensity * SHAKE_REDUCTION_CONSTANT
	offset.y = SHAKE_MAX_OFFSET.y * shake_amount * randf_range(-1.0, 1.0) * OPT.screen_shake_intensity * SHAKE_REDUCTION_CONSTANT
