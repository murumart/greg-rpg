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
	if ResMan.get_character("greg").level > 95 and DAT.get_data("heard_warstory", false):
		ending_2.play()
		return
	ending_1.play()
