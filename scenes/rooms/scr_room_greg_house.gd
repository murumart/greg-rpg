extends Room

@onready var intro_animator := $Cutscenes/InitialIntro
@export var intro_dialogue_progress := 0
@onready var room_gate := $Areas/RoomGate

@onready var zerma := $Cutscenes/Zerma
@onready var car := $Cutscenes/ZermCar

var zerma_battle := BattleInfo.new().set_music("greg_battle").set_enemies(["zerma"]).\
set_background("greghouse").set_start_text("you will be so educated!")


# fantastic function.
func _ready() -> void:
	super._ready()
	intro_dialogue_progress = DAT.A.get("intro_dialogue_progress", 0)
	intro_dialogue_progress = 2
	DAT.set_data("fought_grandma", true)
	if not DAT.A.get("intro_cutscene_finished", false):
		if intro_dialogue_progress <= 0:
			DAT.capture_player("intro_cutscene")
			intro_animator.play("intro")
		else:
			intro_animator.play("zerm_is_outside")
			if DAT.A.get("fought_grandma", false):
				if DAT.A.get("zerma_fought", false):
					if DAT.A.get("zerma_left", false):
						zerma.global_position = Vector2(124125, 12414125)
						zerma.set_physics_process(false)
						car.global_position = Vector2(21932, 214582158)
						car.set_physics_process(false)
						room_gate.global_position = Vector2(351, 232)
						return
					zerma.global_position = Vector2(-24, 96)
					SOL.dialogue("zerma_after_fight")
					await SOL.dialogue_closed
					zerma.set_target(Vector2(-15, 196))
					zerma.set_state(OverworldCharacter.States.WANDER)
					zerma.default_lines.clear()
					zerma.default_lines.append(&"zerma_goodbye")
					zerma.inspected.connect(_on_zerma_inspected)
					room_gate.global_position = Vector2(351, 232)
					return
				SOL.dialogue("zerma_fight_preface")
				zerma.set_target(Vector2(-24, 96))
				zerma.set_state(OverworldCharacter.States.WANDER)
				await SOL.dialogue_closed
				if SOL.dialogue_choice == "yes":
					LTS.enter_battle(zerma_battle)
					SOL.dialogue_choice = ""
				else:
					intro_animator.play("zerma_leaves")
				return
			return
	else:
		room_gate.global_position = Vector2(351, 232)
		$Cutscenes.global_position = Vector2(10000, 10000)
		$Cutscenes.visible = false


func _on_zerma_inspected() -> void:
	await SOL.dialogue_closed
	intro_animator.play("zerma_leaves")
	DAT.set_data("zerma_left", true)
	room_gate.global_position = Vector2(351, 232)


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
	DAT.free_player("intro_cutscene")


func _save_me() -> void:
	super._save_me()
	DAT.set_data("intro_dialogue_progress", intro_dialogue_progress)
