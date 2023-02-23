extends Room

@onready var intro_animator := $Cutscenes/InitialIntro
@export var intro_dialogue_progress := 0
@onready var room_gate := $Areas/RoomGate


func _ready() -> void:
	super._ready()
	intro_dialogue_progress = DAT.A.get("intro_dialogue_progress", 0)
	if not DAT.A.get("intro_cutscene_finished", false):
		room_gate.global_position = Vector2(100000, 1000)
		if intro_dialogue_progress <= 0:
			intro_animator.play("intro")
		else:
			intro_animator.play("zerm_is_outside")


func intro_cutscene_dialogue() -> void:
	if SOL.dialogue_open: return
	match intro_dialogue_progress:
		0:
			SOL.dialogue("intro_convo_2")
			intro_dialogue_progress = 1
		1:
			SOL.dialogue("intro_convo_3")
			intro_dialogue_progress = 2


func intro_cutscene_first_pause() -> void:
	intro_animator.pause()
	if SOL.dialogue_open:
		await SOL.dialogue_closed
	SOL.dialogue("intro_convo_4")
	await SOL.dialogue_closed
	intro_animator.play("intro")


func _save_me() -> void:
	super._save_me()
	DAT.set_data("intro_dialogue_progress", intro_dialogue_progress)
