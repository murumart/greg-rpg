extends Room

@onready var sprite := $SprIcon
var speed := 60.0


func _ready() -> void:
	$Button.connect("pressed", save_pressed)
	$Button2.connect("pressed", load_pressed)
	$Button3.connect("pressed", shake_pressed)
	$Button4.connect("pressed", trash_pressed)
	$Button5.connect("pressed", speak_pressed)
	$Button6.connect("pressed", dialogue_speak_pressed)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		$RichTextLabel.skip_to_end()


func _physics_process(delta: float) -> void:
	sprite.global_position.x += int(Input.get_axis("ui_left", "ui_right") * delta * speed)
	sprite.global_position.y += int(Input.get_axis("ui_up", "ui_down") * delta * speed)


func save_pressed():
	DAT.save_data()


func load_pressed():
	print(DIR.load_data())


func shake_pressed():
	$Greg/Camera.add_trauma(1.0)


func trash_pressed():
	DAT.set_data(str(randf_range(-1, 1)), (str(randf_range(-100, 100))))
	DAT.print_data()


func speak_pressed():
	$RichTextLabel.visible_ratio = 0.0
	$RichTextLabel.text = str(randi())
	$RichTextLabel.speak_text({"speaking_speed": randf_range(0.5, 2.0)})


func dialogue_speak_pressed():
	SOL.dialogue("test")
