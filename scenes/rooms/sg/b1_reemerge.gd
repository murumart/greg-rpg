extends TileMapLayer

var piuzzle_progress: int:
	set(to): DAT.set_data("sg_b4_piuzzl2_progress", to)
	get: return DAT.get_data("sg_b4_piuzzl2_progress", 0)


func _ready() -> void:
	if not (piuzzle_progress & 0b11):
		hide()
		return
	$Block.queue_free()
