extends Node2D

@onready var woods_guy: OverworldCharacter = $WoodsGuy
@onready var spots: Node = $Spots

const LINE := "woods_guy_"
const DONT_TELEPORT := ["no", "darn"]


func _ready() -> void:
	var level := DAT.get_character("greg").level
	if level < 55:
		woods_guy.queue_free()
		return
	woods_guy.global_position = spots.get_children(
		).pick_random().global_position
	woods_guy.default_lines = []
	if level >= 60:
		woods_guy.default_lines.append(LINE + str(randi() % 6))
	else:
		woods_guy.default_lines.append("woods_guy_tooearly")
	woods_guy.inspected.connect(_on_inspected)


func _on_inspected() -> void:
	SOL.dialogue_closed.connect(
		func():
			if SOL.dialogue_choice not in DONT_TELEPORT:
				LTS.level_transition("res://scenes/rooms/scn_room_forest.tscn")
	, CONNECT_ONE_SHOT)
