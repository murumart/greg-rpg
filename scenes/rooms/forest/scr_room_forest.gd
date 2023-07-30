extends Room

enum {NORTH, SOUTH, EAST, WEST}

func _ready() -> void:
	super._ready()
	
	for i in $Gates.get_child_count():
		($Gates.get_child(i) as Area2D).body_entered.connect(gate_entered.bind(i).unbind(1))


func gate_entered(which: int) -> void:
	print(which)
