class_name Campfire extends Node2D

@export var lit := false:
	set(to):
		DAT.set_data(save_key("lit"), to)
	get:
		return DAT.get_data(save_key("lit"), false)

var exchanges: Dictionary[StringName, Exchange] = {}

@onready var timer := $Timer as Timer
var flames := preload("res://scenes/vfx/scn_vfx_battle_burning.tscn")
var explode := preload("res://scenes/vfx/scn_vfx_explosion.tscn")


func _ready() -> void:
	timer.start(1.0)
	timer.timeout.connect(process)
	exchanges["warmmeat"] = Exchange.new().set_input(["frozen_meat"]).set_output(["meat"])
	exchanges["cookmeat"] = Exchange.new().set_input(["meat"]).set_output(["meat_cooked"])
	exchanges["cookegg"] = Exchange.new().set_input(["egg"]).set_output(["eggshell", "egg_cooked"])


func _on_inspected() -> void:
	var dlg := DialogueBuilder.new()
	var greg := ResMan.get_character(&"greg")
	if not lit:
		dlg.al("a campfire spot. hasn't been used in a while.")
		if &"lighter" in greg.inventory:
			dlg.al("you have a lighter. would you like to light this?").schoices(["yes", "no"])
			var choice := await dlg.speak_choice()
			if choice == "yes":
				light()
			return
		elif &"skystorm" in greg.unused_spirits or &"skystorm" in greg.spirits:
			dlg.al("you have a fire in your soul. would you like to light this?").schoices(["yes", "no"])
			var choice := await dlg.speak_choice()
			if choice == "yes":
				var sprt := ResMan.get_spirit(&"skystorm")
				if greg.magic < sprt.cost:
					dlg.clear()
					dlg.al("but there was not enough spirit power.")
					await dlg.speak_choice()
					return
				greg.magic -= sprt.cost
				SOL.vfx(sprt.animation)
				light()
			return
		return
	dlg.clear()
	dlg.al("this campfire is alight.")
	dlg.al("you could use the fire to make things. do you want to look closer?").schoices(["yes", "no"])
	var choice := await dlg.speak_choice()
	if choice == "no":
		return
	while true:
		dlg.clear()
		dlg.al("what would you like to do?")\
			.schoices(Math.reaap(exchanges.keys(), "exit"))
		var c := await dlg.speak_choice()
		if c in exchanges.keys():
			dlg.clear()
			dlg.al("you really want to %s?" % c).schoices(["yes", "no", "info"])
			var cf := await dlg.speak_choice()
			if cf == "yes":
				var success := exchanges[c].exchange(
					ResMan.get_character("greg").inventory)
				if not success:
					exchanges[c].state(Exchange.Statements.CRITERIA)
				else:
					add_child(explode.instantiate())
				await SOL.dialogue_closed
			elif cf == "info":
				exchanges[c].state(Exchange.Statements.CRITERIA)
				exchanges[c].state(Exchange.Statements.RETURNS)
				await SOL.dialogue_closed
		else:
			return


func light() -> void:
	lit = true


func process() -> void:
	if lit:
		add_child(flames.instantiate())


func save_key(key: String) -> String:
	return "campfire_%s_in_%s_%s" % [name.to_snake_case(), DAT.get_data("current_room"), key]
