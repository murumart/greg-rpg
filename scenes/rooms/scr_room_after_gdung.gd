extends Room

@onready var ending_1 := $Ending1
@onready var bike: Node2D = $InteriorTiles/Decor/Bike


func _ready() -> void:
	super()
	if not 0 in DAT.get_data("bike_ghosts_fought", []):
		bike.queue_free()
	if LTS.gate_id == LTS.GATE_EXIT_BATTLE:
		select_ending()
		return
	$InteriorTiles/Grandma/EnterArea.monitoring = true


func select_ending() -> void:
	ending_1.play()

