extends Node

# handles changing scenes

signal scene_changed

const ROOM_SCENE_PATH := "res://scenes/rooms/scn_room_%s.tscn"

# this specifies the type of change between scenes
var gate_id : StringName
const GATE_LOADING := &"loading"
const GATE_EXIT_BATTLE := &"battle_exit"
const GATE_EXIT_BIKING := &"bike_exit"
const GATE_EXIT_FISHING := &"fishing_exit"
const PLAYER_POSITION_LOAD_GATES := [GATE_LOADING, GATE_EXIT_BATTLE, GATE_EXIT_BIKING, GATE_EXIT_FISHING, GATE_EXIT_CUTSCENE, GATE_EXIT_GAMING] # player position gets set to one saved in data if gate is one of these
const GATE_BIKE_TRAVEL := &"bike_travel"
const GATE_EXIT_CUTSCENE := &"curscene_exit"
const GATE_EXIT_GAMING := &"gaming_exit"

var entering_battle := false


func _init() -> void:
	pass


# instead of get_tree().change_scene() or whatever
func change_scene_to(path: String, options := {}) -> void:
	get_tree().root.get_child(-1).queue_free()
	var free_us := get_tree().get_nodes_in_group("free_on_scene_change")
	DAT.set_data("changing_scene_to", path)
	if options.get("free_those_nodes", true):
		for node in free_us:
			node.call_deferred("queue_free")
	await get_tree().process_frame
	var new_scene : Node = load(path).instantiate()
	get_tree().root.call_deferred("add_child", new_scene, false)
	if new_scene.has_method("_option_init"): new_scene._option_init(options)
	
	if options.get("free_player", true):
		DAT.free_player("level_transition")
	scene_changed.emit()


# change level with fancy fade
func level_transition(path: String, op := {}) -> void:
	DAT.capture_player("level_transition")
	get_tree().call_group("free_on_level_transition", "queue_free")
	var fadetime : float = op.get("fade_time", 0.4)
	SOL.fade_screen(
		op.get("start_color", Color(0, 0, 0, 0)),
		op.get("end_color", Color.BLACK),
		fadetime
	)
	await SOL.fade_finished
	DAT.save_nodes_data()
	change_scene_to(path, op)
	await scene_changed
	if not op.get("abrupt_end", false):
		SOL.fade_screen(
			op.get("end_color", Color.BLACK),
			op.get("start_color", Color(0, 0, 0, 0)),
			fadetime
		)
	else:
		SOL.fade_screen(Color.TRANSPARENT, Color.TRANSPARENT, 0.1)
	if op.get("stealing_enabled", true):
		handle_stolen_items()


func to_game_over_screen() -> void:
	SND.play_song("", 100.0)
	level_transition("res://scenes/gui/scn_death_screen.tscn", {"stealing_enabled": false})


func enter_battle(info: BattleInfo) -> void:
	if entering_battle: return
	entering_battle = true
	gate_id = "entering_battle"
	get_tree().call_group("free_on_level_transition", "queue_free")
	DAT.capture_player("entering_battle")
	SND.play_song("", 100.0, {save_audio_position = true})
	SOL.vfx("battle_enter", Vector2())
	await get_tree().create_timer(3.0).timeout
	DAT.save_nodes_data()
	change_scene_to("res://scenes/tech/scn_battle.tscn", {"battle_info": info})
	await scene_changed
	entering_battle = false
	DAT.free_player("entering_battle")


# this matters when exiting the store
func handle_stolen_items() -> void:
	var stolen_items : Array = DAT.get_data("unpaid_items", [])
	if stolen_items.is_empty(): return
	DAT.set_data("unpaid_items", [])
	for i in stolen_items:
		DAT.grant_item(i)
		DAT.incri("stolen_from_store", DAT.get_item(i).price)
		await SOL.dialogue_closed
