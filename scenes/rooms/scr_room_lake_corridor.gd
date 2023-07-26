extends Room
@onready var naturalist: OverworldCharacter = $Naturalist


func _ready() -> void:
	super._ready()
	var level := DAT.get_character("greg").level
	if level < 25:
		SOL.dialogue_box.dial_concat("naturalist_lake_underleveled", 2, [level])
		naturalist.default_lines = [
			"naturalist_lake_underleveled", "naturalist_lake_underleveled_2"]
	else:
		naturalist.default_lines = ["naturalist_lake_birds"]
