extends Node2D

const NEIGHBOUR_WIFE_CYCLE = 470

var store_cashier: StoreCashier

@onready var products := get_tree().get_nodes_in_group("products")


func _ready() -> void:
	pass


func product_placement() -> void:
	for x in products:
		if randf() <= 0.5:
			x.visible = not x.visible
			x.get_node("StaticBody2D").get_child(0).disabled = not x.visible
			x.get_node("InspectArea").get_child(0).disabled = not x.visible
		x.global_position += Vector2(randi_range(-2, 2), randi_range(-2, 2))


# the neighbour wife can appear in the store
func neighbour_wife_position() -> void:
	var neighbour_wife := $NeighbourWife
	if store_cashier.cashier == "dead":
		neighbour_wife.queue_free()
		return
	var time := wrapi(DAT.seconds, 0, NEIGHBOUR_WIFE_CYCLE)
	if time < NEIGHBOUR_WIFE_CYCLE / 2:
		neighbour_wife.queue_free()
