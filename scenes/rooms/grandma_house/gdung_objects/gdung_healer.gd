extends Node2D

var eaten: bool:
	get:
		return DAT.get_data(get_save_key(), false)
	set(to):
		DAT.set_data(get_save_key(), to)

@onready var plants: Sprite2D = $Plants



func _ready() -> void:
	if eaten:
		plants.hide()


func _on_interaction() -> void:
	if eaten:
		SOL.dialogue("gdung_healer_eaten")
		return
	SOL.dialogue("gdung_healer")
	await SOL.dialogue_closed
	if SOL.dialogue_choice == &"yes":
		eaten = true
		plants.hide()
		SND.play_sound(preload("res://sounds/greenhouse_heal_big.ogg"))
		for c in DAT.get_data("party", ["greg"]):
			ResMan.get_character(c).fully_heal()


func get_save_key() -> StringName:
	# doesn't work in gdung anymore. thats ok
	return "gdung_healer_" + str(LTS.get_current_scene().name) + "_eaten"
