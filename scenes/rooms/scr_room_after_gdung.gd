extends Room

@onready var ending_1 := $Ending1
@onready var ending_2 := $Ending2


func _ready() -> void:
	super()
	if LTS.gate_id == LTS.GATE_EXIT_BATTLE:
		select_ending()
		return
	$InteriorTiles/Grandma/EnterArea.monitoring = true


func select_ending() -> void:
	ending_2.play()

