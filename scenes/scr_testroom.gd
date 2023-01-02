extends Room


func _ready() -> void:
	$Button.connect("pressed", save_pressed)
	$Button2.connect("pressed", load_pressed)


func save_pressed():
	DAT.save_data()


func load_pressed():
	print(DIR.load_data())

