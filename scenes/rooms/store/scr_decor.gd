extends Node2D

const NEIGHBOUR_WIFE_CYCLE = 470

var store_cashier: StoreCashier
@onready var cashier := $"../Kassa/Cashier" as OverworldCharacter
@onready var wli_particles: GPUParticles2D = $"../Kassa/Cashier/WLIParticles"

@onready var products := get_tree().get_nodes_in_group("products")
@onready var funny_area: Area2D = $FunnyArea
@onready var greg: PlayerOverworld = $"../Greg"
@onready var camera := $"../Greg/Camera"
@onready var canvas_modulate: CanvasModulate = $CanvasModulate


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
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(camera, "global_position", cashier.global_position, 4.0)
	SOL.dialogue_box.started_speaking.connect(_bits)
	cashier.speed = 0
	cashier.direct_walking_animation(greg.global_position - cashier.global_position)
	tw.parallel().tween_property(canvas_modulate, "color",
			(Color(0.51764708757401, 0.66666668653488, 0.59607845544815)), 10.0)
	await SOL.dialogue_closed
	SND.play_sound(preload("res://sounds/spirit/wli_up.ogg"))
	tw = create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(cashier, "global_position", greg.global_position + Vector2(0, -18), 1.0)
	tw.parallel().tween_property(camera, "global_position", greg.global_position + Vector2(0, -18), 1.6)
	tw.finished.connect(func():
		SOL.dialogue("cashier_mean_mean")
		tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_loops()
		tw.tween_property(camera, "zoom", Vector2(1.5, 1.5), 3.5)
		tw.tween_property(camera, "zoom", Vector2.ONE, 3.5)
		SOL.dialogue_closed.connect(func():
			SND.play_sound(preload("res://sounds/spirit/wli_down.ogg"))
			await create_tween().tween_interval(1.0).finished
			LTS.enter_battle(preload("res://resources/battle_infos/cashier_fight.tres"))
		, CONNECT_ONE_SHOT)
	)


func funny() -> void:
	if DAT.seconds - DAT.get_data("fake_game_over_second", -1000) < 10:
		return
	DAT.set_data("fake_game_over_second", DAT.seconds)
	DAT.save_to_dict()
	LTS.gate_id = &"fake_game_over"
	LTS.to_game_over_screen()


func _bits(line: int) -> void:
	if line == 4:
		wli_particles.show()
		create_tween().tween_property(wli_particles, "modulate:a", 1.0, 6.0).from(0.0)
	elif line == 6:
		SND.play_song("ac_scary")
		SOL.dialogue_box.started_speaking.disconnect(_bits)
