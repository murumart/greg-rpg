extends BattleEnemy

const END_TURN = 40

@onready var time_for_pizz: Control = $TimeForPizz
@onready var power_label: Label = $TimeForPizz/PowerLabel
@onready var canvas_group: Node2D = $Node/CanvasGroup

var electric_power : float = 0.0


func _ready() -> void:
	super()
	remove_child(time_for_pizz)
	SOL.add_ui_child(time_for_pizz)
	crit_chance = 0.02
	# move the message container down so it doesn't obscure the power label
	if LTS.get_current_scene().name == "Battle":
		LTS.get_current_scene().log_text.position.y += 8


func _process(delta: float) -> void:
	super(delta)
	power_label.modulate.b = minf(1.0 - (electric_power * 0.04), 1.0)
	var electric := get_status_effect("electric")
	power_label.text = "p o w e r : " + (
			str(electric.strength) if electric else "0")
	canvas_group.material.set("shader_parameter/iridescence_reducer",
			character.health_perc() * 0.85)
	animator.speed_scale = 2.4 - character.health_perc() * 1.2


func ai_action() -> void:
	_monologue()
	if SOL.dialogue_open:
		await SOL.dialogue_closed
	if turn >= END_TURN: # pizz arrival
		DAT.death_reason = "president_gun"
		_pizz_arrival_animation()
		return
	super()
	if turn % 3 == 0:
		_increase_electric(0.5)


func hurt(amount: float, h_gender: int) -> void:
	if character.health - absi(amount) <= 0:
		DAT.set_data("you_gotta_see_the_water_drain", true)
		animate("death")
		SND.play_sound(preload("res://sounds/spirit/dish_end.ogg"))
		SND.play_song("", 1281)
		var tw := create_tween().set_loops(8)
		tw.tween_callback(func():
			SOL.vfx("explosion",
					$Node/CanvasGroup/Head.global_position + Vector2(
							randf_range(-50, 50), randf_range(-50, 50)
					),
					{"silent": true, "scale": Vector2(0.2, 0.2)}))
		tw.tween_interval(0.3)

		auto_ai = false
		await create_tween().tween_interval(2.0).finished
		SOL.dialogue("president_die_die_die")
		await SOL.dialogue_closed
	super(amount, gender)
	if h_gender == Genders.ELECTRIC and not DAT.get_data(
				"president_mentioned_electric_resistance"):
		DAT.set_data("president_mentioned_electric_resistance", true)
		SOL.dialogue("president_resistance")


func _spirit_dish_buff_used_on() -> void:
	_increase_electric(1.0)


func _increase_electric(amount: float) -> void:
	var electric := get_status_effect("electric")
	electric_power = electric.strength if electric else electric_power
	add_status_effect_s("electric", electric_power + amount, 10)


func _pizz_arrival_animation() -> void:
	auto_ai = false
	$Node/FunnyCutscenePeople.animate()


func _monologue() -> void:
	var title := "president_monologue_" + str(turn)
	if SOL.dialogue_exists(title):
		SOL.dialogue(title)


func _president_slide(out: bool) -> void:
	var president: Sprite2D = $Node/FunnyCutscenePeople/President
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(president,
			"global_position:x", 0.0 if not out else 200.0, 0.3)
