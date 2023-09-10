class_name Campfire extends Node2D

@export var lit := false
var exchanges := {}

@onready var timer := $Timer as Timer
var flames := preload("res://scenes/vfx/scn_vfx_battle_burning.tscn")
var explode := preload("res://scenes/vfx/scn_vfx_explosion.tscn")


func _ready() -> void:
	timer.start(1.0)
	timer.timeout.connect(process)
	exchanges["cookmeat"] = Exchange.new().set_input(["meat"]
	).set_output(["meat_cooked"])
	exchanges["cookegg"] = Exchange.new().set_input(["egg"]
	).set_output(["eggshell", "egg_cooked"])
	lit = DAT.get_data(save_key("lit"), false)


func _on_inspected() -> void:
	if not lit:
		SOL.dialogue("insp_campfire_site")
		if DAT.get_character("greg").inventory.has("lighter"):
			SOL.dialogue("insp_campfire_has_lighter")
			SOL.dialogue_closed.connect(
				func(): if SOL.dialogue_choice == "yes": light(), CONNECT_ONE_SHOT)
		return
	SOL.dialogue("insp_lit_campfire")
	SOL.dialogue_closed.connect(func():
		if SOL.dialogue_choice == "yes":
			SOL.dialogue_box.adjust(
			"campfire_exchanges", 0, "choices", Math.reaap(exchanges.keys(), "exit"))
			SOL.dialogue("campfire_exchanges")
			SOL.dialogue_closed.connect(func():
				if SOL.dialogue_choice in exchanges.keys():
					var key := SOL.dialogue_choice
					SOL.dialogue_box.dial_concat("campfire_exchange_confirm", 0, [key])
					SOL.dialogue("campfire_exchange_confirm")
					SOL.dialogue_closed.connect(func():
						if SOL.dialogue_choice == "yes":
							var success := exchanges[key].exchange(
							DAT.get_character("greg").inventory) as bool
							if not success:
								exchanges[key].state(Exchange.Statements.CRITERIA)
							else:
								add_child(explode.instantiate())
						elif SOL.dialogue_choice == "info":
							exchanges[key].state(Exchange.Statements.CRITERIA)
							exchanges[key].state(Exchange.Statements.RETURNS)
					, CONNECT_ONE_SHOT)
			, CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT)


func light() -> void:
	lit = true


func process() -> void:
	if lit:
		add_child(flames.instantiate())


func _save_me() -> void:
	DAT.set_data(save_key("lit"), lit)


func save_key(key: String) -> String:
	return "campfire_%s_in_%s_%s" % [name.to_snake_case(), DAT.get_data("current_room"), key]

