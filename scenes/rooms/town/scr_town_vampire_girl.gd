extends Node2D

const CYCLE := 180
const INTERACTED := &"vampire_girl_interaction"
const INTERACTIONS := &"girl_interactions"

var imminence: int = 0
var bad_condition := false

@onready var girl := $Girl as OverworldCharacter
@onready var position_markers: Node2D = $PositionMarkers


func _ready() -> void:
	var level := DAT.get_character("greg").level
	if level < 40 or level >= 50:
		bad_condition = true
		queue_free()
		return
	imminence = 50 - level
	if DAT.seconds % CYCLE > (imminence + 1) * 30:
		bad_condition = true
		queue_free()
		DAT.set_data(INTERACTED, false)
		print("not her time")
		return
	girl.inspected.connect(_on_interaction)
	girl.default_lines.append("girl_" + str(randi_range(1, 5)))
	girl.global_position = get_rand_pos()


# note that interacted signal is called before the npc's dialogue logic is ran.
func _on_interaction() -> void:
	if not DAT.get_data(INTERACTED, false):
		DAT.incri(INTERACTIONS, 1)
	DAT.set_data(INTERACTED, true)
	if girl.default_lines.size():
		SOL.dialogue_closed.connect(func():
			girl.default_lines.clear()
		, CONNECT_ONE_SHOT)


func get_rand_pos() -> Vector2:
	return position_markers.get_children().pick_random().global_position


func _save_me() -> void:
	if LTS.gate_id != LTS.GATE_LOADING:
		DAT.set_data(INTERACTED, false)
