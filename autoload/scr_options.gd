extends Node

# options menu

var screen_shake_intensity = 1.0

var text_speak_time = 0.75 # in seconds


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_KP_1:
				DAT.get_character(0).level_up()


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
