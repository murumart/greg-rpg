extends Node2D

const STORE_CLEANUP_TIME_SECONDS := 400

@onready var store_door := $DoorArea
@onready var guy: OverworldCharacter = $UguyWalk
@onready var boot_trash: TrashBin = $Strash3


func setup() -> void:
	_store_door_setup()
	lake_hint_npc_setup()
	_guy_setup()


func _store_door_setup() -> void:
	var current_cashier := StoreCashier.which_cashier_should_be_here()
	var stolen: int = DAT.get_data("stolen_from_store", 0)
	var cleanup_start_second: int = DAT.get_data("store_cleanup_started_second", -31399)
	if (stolen > 199
			and not DAT.get_data("cashier_dead", false)
			and current_cashier == "nice"):
		store_door.destination = ""
	if (store_door.destination != ""
			and current_cashier == "absent"):
		store_door.destination = ""
		store_door.fail_dialogue = "store_cashier_absent"
	if (store_door.destination != ""
			and DAT.seconds - cleanup_start_second < STORE_CLEANUP_TIME_SECONDS):
		store_door.destination = ""
		store_door.fail_dialogue = "store_under_cleanup"


func lake_hint_npc_setup() -> void:
	var npc := $LakeHintNpc as OverworldCharacter
	var time := DAT.seconds % DAT.LAKE_HINT_CYCLE as int
	var cyc := DAT.LAKE_HINT_CYCLE as int
	if "lakeside" not in DAT.get_data("visited_rooms", []) and not (Math.inrange(time, cyc * 0.33, cyc * 0.66)):
		npc.queue_free()
		DAT.set_data("lake_hint_received", false)
		return
	npc.inspected.connect(_on_lake_hint_received)
	var level := ResMan.get_character("greg").level
	if level >= 24 and not "lakeside" in DAT.get_data("visited_rooms", []):
		npc.default_lines.append("lake_hint")
		return
	npc.default_lines.append("lake_hint_" + str((randi() % 8) + 1))
	npc.default_lines.append("lake_hint_continue")


func _on_lake_hint_received(force_cutscene: bool = false) -> void:
	var cs := $StoreCutscenePlayer as AnimationPlayer
	if not DAT.get_data("lake_hint_received", false):
		DAT.incri("store_ad_progress", 1)
	DAT.set_data("lake_hint_received", true)
	if force_cutscene or (DAT.get_data("store_ad_progress", 0) >= 3 and
			not DAT.get_data("saw_ad_cutscene", false)):
		DAT.set_data("saw_ad_cutscene", true)
		DAT.capture_player("cutscene")
		cs.play("cutscene_start")
		cs.animation_finished.connect(func(_a):
			SOL.dialogue("lake_hint_cutscene_1")
			SOL.dialogue_closed.connect(func():
				cs.play("cutscene_end")
				DAT.free_player("cutscene")
			, CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT)


func _guy_setup() -> void:
	if (store_door.destination == ""
			or LTS.gate_id == &"store_inside-outside" or LTS.gate_id == LTS.GATE_LOADING
			or Math.inrange(ResMan.get_character("greg").level, 40, 50)
			or not Math.inrange(DAT.playtime % 190, 90, 160)):
		guy.queue_free()
		return

	guy.target_reached.connect(_guy_target_reached)


func _guy_target_reached() -> void:
	var which := guy.at_which_path_point()
	if which == $UguyPath/UguyPath11:
		guy.default_lines.clear()
		guy.default_lines.append("guy_walk_home_door")
		guy.path_container = null
		await Math.timer(2.0)
		guy.default_lines.clear()
		var tw := create_tween()
		tw.tween_property(guy, "modulate:a", 0.0, 1.0)
		tw.finished.connect(guy.queue_free)
