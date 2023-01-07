extends Resource
class_name Character

# this will be interpreted by the battle system and dialogue system

@export var id_name : StringName = &""

@export_group("Appearance")
@export var name := ""
@export var voice_sound : AudioStream
@export var portrait : Texture

@export_group("Stats")
@export var max_health := 100.0
@export var health := 100.0
@export var max_magic := 30.0
@export var magic := 30.0

@export_range(1, 99) var level := 1
var experience := 0.0
@export_range(1.0, 99.0) var attack := 1.0
@export_range(1.0, 99.0) var defense := 1.0
@export_range(1.0, 99.0) var speed := 1.0

@export_group("Items")
@export var inventory : Array[int] = []
@export var armour : int = -1
@export var weapon : int = -1


func get_saveable_dict() -> Dictionary:
	return {
		"max_health": max_health,
		"health": health,
		"max_magic": max_magic,
		"magic": magic,
		"level": level,
		"experience": experience,
		"attack": attack,
		"defense": defense,
		"speed": speed,
		"inventory": inventory,
		"armour": armour,
		"weapon": weapon,
	}


func load_from_dict(dict: Dictionary) -> void:
	for k in dict.keys():
		set(k, dict[k])
