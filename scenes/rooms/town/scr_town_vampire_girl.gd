extends Node2D

const CYCLE := 300
const INTERACTED := &"vampire_girl_interaction"
const INTERACTIONS := &"girl_interactions"

var imminence: int = 0

@onready var girl := $Girl as OverworldCharacter
@onready var position_markers: Node2D = $PositionMarkers


func _ready() -> void:
	var level := DAT.get_character("greg").level
	if level < 40 or level >= 50:
		queue_free()
		return
	imminence = 50 - level
	if DAT.seconds % CYCLE > (imminence + 1) * 30:
		queue_free()
		DAT.set_data(INTERACTED, false)
		return
	girl.inspected.connect(on_interaction)
	girl.default_lines.append("girl_" + str(randi_range(1, 5)))
	girl.global_position = get_rand_pos()


func on_interaction() -> void:
	if not DAT.get_data(INTERACTED, false):
		DAT.incri(INTERACTIONS, 1)
	DAT.set_data(INTERACTED, true)
	girl.default_lines.clear()


func get_rand_pos() -> Vector2:
	return position_markers.get_child(randi() % position_markers.get_child_count()).global_position
