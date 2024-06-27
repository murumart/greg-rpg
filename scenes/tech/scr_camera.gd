extends Camera2D

# all cameras should have this script

# screen shake variables
const SHAKE_DECAY := 0.8
const SHAKE_MAX_OFFSET := Vector2(100, 75)
const SHAKE_REDUCTION_CONSTANT := 0.05

var shake_trauma := 0.0
var shake_trauma_power := 2

var free_cam := false


func _ready() -> void:
	# needed due to godot 4 beta somethingsomething camera changes
	make_current()


func add_trauma(amount: float) -> void:
	shake_trauma = minf(shake_trauma + amount, 1.0)


func _physics_process(delta: float) -> void:
	shake_trauma = move_toward(shake_trauma, 0.0, SHAKE_DECAY * delta)

	var shake_amount := pow(shake_trauma, shake_trauma_power)
	offset.x = SHAKE_MAX_OFFSET.x * shake_amount * randf_range(-1.0, 1.0) * OPT.get_opt("screen_shake_intensity") * SHAKE_REDUCTION_CONSTANT
	offset.y = SHAKE_MAX_OFFSET.y * shake_amount * randf_range(-1.0, 1.0) * OPT.get_opt("screen_shake_intensity") * SHAKE_REDUCTION_CONSTANT

	# free cam cheat (toggle in OPT)
	if free_cam:
		global_position += Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * (1.0 / zoom.x) * get_process_delta_time() * 120.0
		zoom += Math.v2(Input.get_axis("ui_page_down", "ui_page_up")) / 50.0

