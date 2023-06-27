extends Room


func _ready() -> void:
	super._ready()
	
	if not DAT.get_data("trash_guy_inspected", false):
		$Cells/Cell/TrashGuy.queue_free()
		$Cells/Cell/TrashInspect.queue_free()
