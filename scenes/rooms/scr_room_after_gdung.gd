extends Room


func _ready() -> void:
	super()
	if LTS.gate_id == LTS.GATE_EXIT_BATTLE:
		select_ending()
		return
	$InteriorTiles/Grandma/EnterArea.monitoring = true


func select_ending() -> void:
	return
