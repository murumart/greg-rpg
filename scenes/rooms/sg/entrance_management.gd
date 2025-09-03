extends Sprite2D


func _ready() -> void:
	if DAT.get_data("sg_y_7_boss_done", false):
		$"..".music = "secret_garden"
		%Darkness.hide()
	else:
		$"..".music = "bells"

	if DAT.get_data("sg_b4_multipanther_fought", false):
		%Black.hide()
		%Stars.show()

	if DAT.get_data("sg_y_7_boss_done", false):
		%BEntrance.disabled = false
		%BEntrance.show()
	if DAT.get_data("sg_b4_multipanther_fought", false):
		%PEntrance.disabled = false
		%PEntrance.show()
