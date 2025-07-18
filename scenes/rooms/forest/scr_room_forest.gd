class_name ForestPath extends Room

const HudType := preload("res://scenes/rooms/forest/scr_forest_hud.gd")

var greenhouse: ForestGenerator.GreenhouseType = null

@onready var greg := $Greg as PlayerOverworld
@onready var greg_actor: BattleActor = $Greg/GregActor
@onready var hit_area: Area2D = $Greg/HitArea

@onready var paths: TilemapLayerParent = $Tilemaps/Paths
var enabled_layer := 0

@onready var current_room := DAT.get_data(
		"forest_depth", 0) as int
var inversion := false

@export_group("Curves")
@export var trash_amount_curve: Curve

var generator: ForestGenerator
var questing: ForestQuesting
@onready var woods_color: ColorContainer = $CanvasModulate/DeepWoods
@onready var hud := $UI as HudType


func _ready() -> void:
	super._ready()
	greg_actor.character = ResMan.get_character("greg")
	hit_area.area_entered.connect(_hit)
	greg_actor.died.connect(_hurt_died.unbind(1))
	if not DAT.get_data("forest_questing", null):
		DAT.set_data("forest_questing", ForestQuesting.new())
	if DAT.get_data("forest_save", {}).is_empty():
		DAT.set_data("forest_save", {})
	questing = DAT.get_data("forest_questing")
	hud.forest_ready(self)
	_setup_gates()
	generator = ForestGenerator.new(self)
	woods_color.color = woods_color.color.lerp(
			Color(0.735, 0.895, 0.222),
			remap(current_room, 0, 100, 0.0, 1.0))
	questing.update_quests()

	if LTS.gate_id == LTS.GATE_EXIT_BATTLE or LTS.gate_id == LTS.GATE_LOADING:
		load_from_save()
		return
	generator.generate()


func _setup_gates() -> void:
	var gates := $Gates
	hud.update_compass(-1)
	for i in gates.get_child_count():
		var gate := gates.get_child(i) as Area2D
		gate.body_entered.connect(
				gate_entered.bind(i).unbind(1))
		if DAT.get_data("forest_last_gate_entered", ForestGenerator.EAST) == i:
			if not LTS.gate_id == LTS.GATE_EXIT_BATTLE:
				greg.global_position = gates.get_child(
						ForestGenerator.dir_oppos(i)).get_child(1).global_position
			hud.update_compass(ForestGenerator.dir_oppos(i))


func gate_entered(which: int) -> void:
	#print("gate ", which)
	LTS.gate_id = &"forest_transition"
	if which != ForestGenerator.dir_oppos(
			DAT.get_data("forest_last_gate_entered", ForestGenerator.EAST)):
		DAT.set_data("forest_last_gate_entered", which)
		LTS.level_transition("res://scenes/rooms/scn_room_forest.tscn")
		DAT.incri("total_forest_rooms_traveled", 1)
		DAT.incri("forest_depth", 1)
		questing.update_room_timed_perks()
		return
	leave()


func load_from_save() -> void:
	#print(" --- loadign forest from memory")
	generator.load_from_save()


func leave() -> void:
	DAT.set_data("forest_save", {})
	DAT.set_data("forest_questing", null)
	DAT.set_data("forest_active_quests", [])
	DAT.set_data("forest_last_gate_entered", ForestGenerator.EAST)
	DAT.set_data("forest_max_depth", maxi(DAT.get_data("forest_depth", 0), DAT.get_data("forest_max_depth", 0)))
	DAT.set_data("forest_depth", 0)
	LTS.gate_id = &"entrance-woods"
	LTS.level_transition("res://scenes/rooms/scn_room_forest_entrance.tscn")


func _hit(_hurter: Area2D) -> void:
	if &"level_transition" in DAT.player_capturers or &"entering_battle" in DAT.player_capturers:
		return
	greg_actor.hurt(20, Genders.NONE)
	hud.update_exp_display()


func _hurt_died() -> void:
	DAT.capture_player("death")
	greg.rotate(PI * 0.5)
	SND.play_song("", 99)
	await Math.timer(1.0)
	LTS.to_game_over_screen()


func _save_me() -> void:
	if LTS.gate_id == LTS.GATE_ENTER_BATTLE or LTS.gate_id == LTS.GATE_LOADING:
		#print(" --- forest saving data!")
		var forest_save: Dictionary = DAT.get_data("forest_save", {})
		var trees_dict := {}
		var bins_dict := {}
		var greenhouse_dict := {
			&"exists": (current_room % ForestGenerator.GREENHOUSE_INTERVAL == 0
					and current_room > 2),
			&"has_vegetables": greenhouse.has_vegetables if greenhouse else false
		}
		var board_dict := {
			&"exists": current_room % ForestGenerator.BOARD_INTERVAL == 0,
			&"position": get_tree().get_first_node_in_group(
					&"forest_quest_boards").global_position
							if current_room % ForestGenerator.BOARD_INTERVAL == 0
							else null
		}
		var objects_dict := generator.generated_objects
		for tree in get_tree().get_nodes_in_group(&"trees"):
			tree = tree as TreeDecor
			trees_dict[tree.global_position] = tree.type
		for bin in get_tree().get_nodes_in_group(&"forest_bins"):
			bin = bin as TrashBin
			bins_dict[bin.global_position] = {
				&"item": bin.item,
				&"silver": bin.silver,
				&"full": bin.full
			}
			bin.replenish_seconds = -1
		forest_save.merge({
			&"layout": enabled_layer,
			&"pscale": paths.scale,
			&"room_nr": current_room,
			&"trees": trees_dict,
			&"bins": bins_dict,
			&"greenhouse": greenhouse_dict,
			&"objects": objects_dict,
			&"board": board_dict,
		}, true)
		DAT.set_data(&"forest_save", forest_save)
