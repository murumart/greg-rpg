extends Node2D

const NEIGHBOUR_WIFE_CYCLE = 470

var store_cashier: StoreCashier
@onready var cashier := $"../Kassa/Cashier" as OverworldCharacter
@onready var wli_particles: GPUParticles2D = $"../Kassa/Cashier/WLIParticles"

@onready var products := get_tree().get_nodes_in_group("products")
@onready var funny_area: Area2D = $FunnyArea


func _ready() -> void:
	funny_area.body_entered.connect(funny.unbind(1))


func product_placement() -> void:
	for x in products:
		if randf() <= 0.5:
			x.visible = not x.visible
			x.get_node("StaticBody2D").get_child(0).disabled = not x.visible
			x.get_node("InspectArea").get_child(0).disabled = not x.visible
		x.global_position += Vector2(randi_range(-2, 2), randi_range(-2, 2))
	if randf() > 0.25:
		funny_area.queue_free()


# the neighbour wife can appear in the store
func neighbour_wife_position() -> void:
	var neighbour_wife := $NeighbourWife
	if store_cashier.cashier == "dead":
		neighbour_wife.queue_free()
		return
	var time := wrapi(DAT.seconds, 0, NEIGHBOUR_WIFE_CYCLE)
	if time < NEIGHBOUR_WIFE_CYCLE / 2:
		neighbour_wife.queue_free()


func dothethingthething() -> void:
	print("hiii")


func funny() -> void:
	if DAT.seconds - DAT.get_data("fake_game_over_second", -1000) < 10:
		return
	DAT.set_data("fake_game_over_second", DAT.seconds)
	DAT.save_to_dict()
	LTS.gate_id = &"fake_game_over"
	LTS.to_game_over_screen()
