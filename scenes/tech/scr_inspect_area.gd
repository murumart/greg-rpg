extends Area2D
class_name InspectArea

# interaction area with convenient dialogue attached

signal inspected

const INTERACTION_DIALOGUE_BASE := "insp_"

@export var key := ""
@export var keys: Array[String]
@export var dialogue: Dialogue
var progress: int = 0
@export var save_progress := false


func _ready() -> void:
	set_collision_layer_value(3, true)
	monitoring = false
	input_pickable = false
	modulate = Color.from_string("#e7a3ff", Color.WHITE)

	if save_progress:
		progress = mini(DAT.get_data(save_key("progress"), 0), keys.size() - 1)


func interacted() -> void:
	inspected.emit()
	if key:
		SOL.dialogue(INTERACTION_DIALOGUE_BASE + key)
	elif keys.size() > 0:
		SOL.dialogue(INTERACTION_DIALOGUE_BASE + keys[progress])
		progress = mini(progress + 1, keys.size() - 1)
		if save_progress:
			DAT.incri(save_key("progress"), 1)
	elif dialogue:
		SOL.dialogue_d(dialogue)


func save_key(n: String) -> String:
	return str("inspect_area_%s_in_%s_%s" % [name, LTS.get_current_scene().name, n])
