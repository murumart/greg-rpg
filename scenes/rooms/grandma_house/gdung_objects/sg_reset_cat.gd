extends "res://scenes/rooms/grandma_house/gdung_objects/sg_cat_owl.gd"

@export var reset_saves: Array[SaveNodePositions]


func interacted() -> void:
	super()
	if SOL.dialogue_open:
		await SOL.dialogue_closed
		if SOL.dialogue_choice == &"yes":
			DAT.save_to_data()
			for r in reset_saves:
				r.erase_saved()
			DAT.load_data_from_dict(DAT.A, true)
