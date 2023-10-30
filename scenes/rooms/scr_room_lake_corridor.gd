extends Room
@onready var naturalist: OverworldCharacter = $Naturalist


func _ready() -> void:
	super._ready()
	var level := DAT.get_character("greg").level
	if level < 25 and not DAT.get_data("naturalist_knows_you_survive_lake", false):
		SOL.dialogue_box.dial_concat("naturalist_lake_underleveled", 2, [level])
		naturalist.default_lines = [
			"naturalist_lake_underleveled", "naturalist_lake_underleveled_2"]
		if spent_adequate_time_at_lake():
			naturalist.default_lines = ["naturalist_lake_underleveled_but_went_and_survived_anyway"]
			DAT.set_data("naturalist_knows_you_survive_lake", true)
	else:
		naturalist.default_lines = ["naturalist_lake_birds"]


func spent_adequate_time_at_lake() -> bool:
	if DAT.get_data("fishings_finished", 0) > 0: return true
	return false
