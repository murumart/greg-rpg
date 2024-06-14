extends Node2D

# bikes that can be used for fast travel
# (hopefully)

const DAT_DESTS := &"_bike_dests"
enum Ghosts {ALPHA, BETA, GAMMA}
const G_DIAL_PREXES = {
	Ghosts.ALPHA: "bike_ghost_",
	Ghosts.BETA: "bike_beta_",
}
const G_REGIONS = {
	Ghosts.ALPHA: Rect2(0, 0, 16, 16),
	Ghosts.BETA: Rect2(16, 0, 16, 16),
}
const G_BATTLE_INFOS = {
	Ghosts.ALPHA: preload("res://resources/battle_infos/bike_ghost_alpha.tres"),
	Ghosts.BETA: preload("res://resources/battle_infos/bike_ghost_beta.tres"),
}
const DIAL_AFTER_DEFEAT := "afterdefeat"
const DIAL_TRAVEL := "travel"
const DIAL_TRAVEL_OPTIONS := "travel_options"
const DIAL_TRAVEL_NODESTS := "travel_nodests"

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var collision: StaticBody2D = $StaticBody2D
@onready var image: Sprite2D = $Ghost/Image
@onready var animator: AnimationPlayer = $AnimationPlayer

@export var ghost: Ghosts = Ghosts.ALPHA
@export var destination_name := &""
@export_file("*.tscn") var destination_path := ""


func _ready() -> void:
	pass


func apply_spawn_point(player: PlayerOverworld) -> void:
	if LTS.gate_id == LTS.GATE_BIKE_TRAVEL:
		player.global_position = $SpawnPoint.global_position


func _interacted() -> void:
	var fought: Array = DAT.get_data("bike_ghosts_fought", [])
	if not ghost in fought:
		_prefight()
		return
	_register()
	SOL.dialogue(G_DIAL_PREXES[ghost] + DIAL_AFTER_DEFEAT)
	await SOL.dialogue_closed
	if SOL.dialogue_choice == &"travel":
		var options := _get_travel_options()
		if not options.is_empty():
			SOL.dialogue_box.adjust(
					G_DIAL_PREXES[ghost] + DIAL_TRAVEL_OPTIONS, 0, "choices", options)
			SOL.dialogue(G_DIAL_PREXES[ghost] + DIAL_TRAVEL_OPTIONS)
			SOL.dialogue_closed.connect(func():
				if SOL.dialogue_choice != &"nvm":
					_travel()
			, CONNECT_ONE_SHOT)
			return
		SOL.dialogue(G_DIAL_PREXES[ghost] + DIAL_TRAVEL_NODESTS)


func _prefight() -> void:
	SND.play_song("")
	SOL.dialogue(G_DIAL_PREXES[ghost] + "interact_1")
	SOL.dialogue_closed.connect(func():
		image.region_rect = G_REGIONS[ghost]
		DAT.capture_player("cutscene")
		animator.play("emerge")
		SND.play_song("bike_spirit_appear",
				10, {volume = -2,
					start_volume = 0.0, play_from_beginning = true})
		await get_tree().create_timer(2.0).timeout
		SOL.dialogue(G_DIAL_PREXES[ghost] + "interact_2")
		SOL.dialogue_closed.connect(
			func():
				DAT.free_player("cutscene")
				LTS.enter_battle(G_BATTLE_INFOS[ghost])
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)


func _register() -> void:
	var dests := get_regs()
	if destination_name in dests.keys():
		return
	var dict := {
		"ghost": ghost,
		"path": destination_path,
	}
	dests[destination_name] = dict
	DAT.set_data(DAT_DESTS, dests)


func _travel() -> void:
	var where := SOL.dialogue_choice
	SOL.dialogue_choice = ""
	SOL.dialogue(G_DIAL_PREXES[ghost] + DIAL_TRAVEL)
	SOL.dialogue_closed.connect(func():
		LTS.gate_id = StringName(LTS.GATE_BIKE_TRAVEL + "_" + where)
		LTS.level_transition((get_regs().get(where, {}) as Dictionary).get(
				"path", "res://scenes/rooms/scn_room_test_room.tscn"))
	, CONNECT_ONE_SHOT)


func _get_travel_options() -> PackedStringArray:
	var options := PackedStringArray()
	options.append("nvm")
	var regs := get_regs()
	for k: StringName in regs:
		var d := regs[k] as Dictionary
		if k == destination_path or d.ghost != ghost:
			continue
		options.append(String(k))
	return options


func get_regs() -> Dictionary:
	return (DAT.get_data(DAT_DESTS, {}) as Dictionary)

