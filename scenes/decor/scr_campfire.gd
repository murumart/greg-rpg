class_name Campfire extends Node2D

@export var lit := false

@onready var timer := $Timer as Timer
var flames := preload("res://scenes/vfx/scn_vfx_battle_burning.tscn")


func _ready() -> void:
	timer.start(1.0)
	timer.timeout.connect(process)


func _on_inspected() -> void:
	if not lit:
		SOL.dialogue("insp_campfire_site")
		if DAT.get_character("greg").inventory.has("lighter"):
			SOL.dialogue("insp_campfire_has_lighter")
			SOL.dialogue_closed.connect(
				func(): if SOL.dialogue_choice == "yes": light(), CONNECT_ONE_SHOT)
		return
	
	SOL.dialogue("insp_lit_campfire")


func light() -> void:
	lit = true


func process() -> void:
	if lit:
		add_child(flames.instantiate())
