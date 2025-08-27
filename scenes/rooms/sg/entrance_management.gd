extends Sprite2D


func _ready() -> void:
	if DAT.get_data("sg_y_7_boss_done", false):
		$"..".music = "secret_garden"
		$"../Greg/Camera/Darkness".hide()
	else:
		$"..".music = "bells"

	if DAT.get_data("sg_y_7_boss_done", false):
		%BEntrance.disabled = false
		%BEntrance.show()
