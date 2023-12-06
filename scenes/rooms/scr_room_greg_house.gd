extends Room

@onready var intro_animator := $Cutscenes/InitialIntro
@export var intro_dialogue_progress := 0
@onready var room_gate := $Areas/RoomGate
@onready var room_gate_2 := $Areas/RoomGate2
@onready var door_area := $Areas/HouseDoor
@onready var door_destination := "grandma_house_inside"

@onready var zerma := $Cutscenes/Zerma
@onready var car := $Cutscenes/ZermCar
@onready var cutscene_node := $Cutscenes

@onready var cat_spawners := [$Areas/Cats1, $Areas/Cats2, $Areas/Cats3, $Areas/Cats4,$Areas/Cats5,$Areas/Cats6,]
@export var zerma_battle : BattleInfo = null


# fantastic function.
func _ready() -> void:
	super._ready()
	if not (DAT.get_data("intro_cutscene_finished") and DAT.get_data("zerma_left")):
		for i in cat_spawners:
			i.queue_free()
			cat_spawners.erase(i)
	zerma.inspected.connect(_on_zerma_inspected)
	intro_dialogue_progress = DAT.get_data("intro_dialogue_progress", 0) if not DAT.get_data("intro_dialogue_progress", 0) == 0 else intro_dialogue_progress
	print("intro progress: ", intro_dialogue_progress)
	door_area.destination = ""
	if DAT.get_data("intro_cutscene_finished", false):
		intro_animator.play("RESET")
		cutscene_node.propagate_call("set_physics_process", [false])
		cutscene_node.visible = false
		cutscene_node.global_position = Vector2(29999, 29999)
		room_gate.global_position = Vector2(339, 232)
		room_gate_2.global_position = Vector2(333, -168)
		return
	
	if intro_dialogue_progress < 2:
		intro_animator.play("intro")
		zerma.default_lines.clear()
		zerma.default_lines.append("intro_inspect_zerma_1")
		room_gate.global_position = Vector2(3399, 232)
		room_gate_2.global_position = Vector2(3399, 232)
		door_area.destination = door_destination
	elif intro_dialogue_progress == 2:
		intro_animator.play("zerm_is_outside")
		intro_animator.advance(10)
		zerma.default_lines.clear()
		zerma.default_lines.append("intro_inspect_zerma_1")
		room_gate.global_position = Vector2(3399, 232)
		room_gate_2.global_position = Vector2(3399, 232)
		door_area.destination = door_destination
		#wawait intro_animator.animation_finished
		print("prenis")
		door_area.apply_spawn_point()
	elif intro_dialogue_progress == 3:
		intro_animator.play("zerm_is_outside")
		intro_animator.advance(3000)
		zerma.move_to(Vector2(-24, 96))
		room_gate.global_position = Vector2(3399, 232)
		room_gate_2.global_position = Vector2(3399, 232)
		zerma.default_lines.append("zerma_fight_preface")
	elif intro_dialogue_progress >= 4:
		intro_animator.play("zerm_is_outside")
		intro_animator.advance(3000)
		zerma.global_position = Vector2(-24, 96)
		room_gate.global_position = Vector2(3399, 232)
		room_gate_2.global_position = Vector2(3399, 232)
		SOL.dialogue("zerma_after_fight")
		await SOL.dialogue_closed
		zerma.move_to(Vector2(-15, 196))
		await zerma.target_reached
		$Greg.saving_disabled = false
		zerma.default_lines.append("zerma_goodbye")


func _on_zerma_inspected() -> void:
	await SOL.dialogue_closed
	match intro_dialogue_progress:
		3:
			if SOL.dialogue_choice == "yes":
				LTS.enter_battle(zerma_battle)
				SOL.dialogue_choice = ""
			elif SOL.dialogue_choice == "no":
				zerma.move_to(Vector2(-15, 196))
				zerma.default_lines.clear()
				await zerma.target_reached
				intro_animator.play("zerma_leaves")
				DAT.set_data("zerma_left", true)
				room_gate.global_position = Vector2(339, 232)
				room_gate_2.global_position = Vector2(333, -168)
				DAT.set_data("intro_cutscene_finished", true)
				SOL.dialogue_choice = ""
		4, 5:
			await get_tree().process_frame
			intro_animator.play("zerma_leaves")
			DAT.set_data("zerma_left", true)
			DAT.set_data("intro_cutscene_finished", true)
			room_gate.global_position = Vector2(339, 232)
			room_gate_2.global_position = Vector2(333, -168)


func intro_cutscene_dialogue() -> void:
	match intro_dialogue_progress:
		0:
			SOL.dialogue("intro_convo_2")
			intro_dialogue_progress = 1
		1:
			SOL.dialogue("intro_convo_3")
			intro_dialogue_progress = 2
			DAT.free_player("intro")


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
