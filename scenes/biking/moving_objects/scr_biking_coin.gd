extends BikingMovingObject


func _ready() -> void:
	super._ready()
	overlap_test()


func overlap_test() -> void:
	if $ManArea.get_overlapping_areas().size() > 0:
		randomise_position()
		overlap_test()
