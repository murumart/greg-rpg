extends Room

@onready var canvas_modulate: CanvasModulate = $CanvasModulate


func _ready() -> void:
	super._ready()


func _on_pole_interacted() -> void:
	SOL.dialogue("fisherwoman_pole_tutorial")
	SOL.dialogue_closed.connect(func():
		SND.play_song("")
		LTS.level_transition("res://scenes/fishing/scn_fishing_minigame.tscn")
		, CONNECT_ONE_SHOT)


func _on_enemy_encounter_area_body_entered(_body: Node2D) -> void:
	create_tween().tween_property(canvas_modulate, "color", Color(
			0.60029411315918, 0.9275940656662, 0.99999982118607), 0.4)


func _on_enemy_encounter_area_body_exited(_body: Node2D) -> void:
	create_tween().tween_property(canvas_modulate, "color", Color.WHITE, 0.4)
