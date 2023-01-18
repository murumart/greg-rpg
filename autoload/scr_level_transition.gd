extends Node

# handles changing scenes

const ROOM_SCENE_PATH := "res://scenes/rooms/scn_room_%s.tscn"


func _init() -> void:
	print("LTS init")


func change_scene_to(path: String, options := {}) -> void:
	get_tree().root.get_child(-1).queue_free()
	var free_us := get_tree().get_nodes_in_group("free_on_scene_change")
	if options.get("free_those_nodes", true):
		for node in free_us:
			node.call_deferred("queue_free")
	await get_tree().process_frame
	var new_scene : Node = load(path).instantiate()
	get_tree().root.call_deferred("add_child", new_scene, false)
	if new_scene.has_method("_option_init"): new_scene._option_init(options)
	if options.get("free_player", true):
		DAT.free_player()


func level_transition(path: String, options := {}) -> void:
	DAT.capture_player()
	var fadetime : float = options.get("fade_time", 0.4)
	SOL.fade_screen(Color(0, 0, 0, 0), Color(0, 0, 0, 1), fadetime)
	await SOL.fade_finished
	DAT.save_nodes_data()
	change_scene_to(path, options)
	SOL.fade_screen(Color(0, 0, 0, 1), Color(0, 0, 0, 0), fadetime)


func enter_battle(options := {}) -> void:
	DAT.capture_player()
	SOL.vfx("battle_enter", Vector2())
	await get_tree().create_timer(3.0).timeout
	change_scene_to("res://scenes/tech/scn_battle.tscn", options)
