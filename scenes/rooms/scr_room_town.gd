extends Room

@onready var store_door := $Houses/Store/DoorArea


func _ready() -> void:
	super._ready()
	
	if DAT.get_data("stolen_from_store", 0) > 199:
		store_door.destination = ""
