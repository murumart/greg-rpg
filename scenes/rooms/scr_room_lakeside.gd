extends Room


func _ready() -> void:
	super._ready()


func _on_pole_interacted() -> void:
	SOL.dialogue("fisherwoman_pole_tutorial")
	SOL.dialogue_closed.connect(func():
		SND.play_song("")
		LTS.level_transition("res://scenes/fishing/scn_fishing_minigame.tscn")
		, CONNECT_ONE_SHOT)
