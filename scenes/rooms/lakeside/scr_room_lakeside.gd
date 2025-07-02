extends Room

@onready var canvas_modulate: ColorContainer = $CanvasModulateGroup/FishWarning
@onready var spawners := get_tree().get_nodes_in_group("thug_spawners")


func _ready() -> void:
	super._ready()
	DAT.set_data("lake_visited", true)
	_fish_victim_setup()
	_car_scared_setup()

	if DAT.get_data("fulfilled_bounty_broken_fishermen", false):
		spawners.map(func(a): a.queue_free())


func _on_pole_interacted() -> void:
	SOL.dialogue("fisherwoman_pole_tutorial")
	SOL.dialogue_closed.connect(func():
		if SOL.dialogue_choice == &"nvm":
			return
		SND.play_song("")
		LTS.level_transition("res://scenes/fishing/scn_fishing_minigame.tscn")
		, CONNECT_ONE_SHOT)


func _on_enemy_encounter_area_body_entered(_body: Node2D) -> void:
	create_tween().tween_property(canvas_modulate, "color", Color(0.592, 0.93, 1.0), 0.4)


func _on_enemy_encounter_area_body_exited(_body: Node2D) -> void:
	create_tween().tween_property(canvas_modulate, "color", Color.WHITE, 0.4)


func _fish_victim_setup() -> void:
	var fish_victim := $Areas/FishVictim as OverworldCharacter
	if DAT.get_data("sunset_triggered", false):
		fish_victim.queue_free()
		return
	fish_victim.inspected.connect(func() -> void:
		if (&"fish_victim_bootful" in fish_victim.default_lines
			or &"fish_victim_bootless_again" in fish_victim.default_lines
		) and ResMan.get_character("greg").armour != &"rubber_boots":
			fish_victim.default_lines = [&"fish_victim_bootless_again"]
		elif ResMan.get_character("greg").armour != &"rubber_boots":
			fish_victim.default_lines = [&"fish_victim_bootless"]
		elif &"fish_victim_bootless" in fish_victim.default_lines:
			if ResMan.get_character("greg").armour == &"rubber_boots":
				fish_victim.default_lines = [&"fish_victim_bootful"]
		elif &"fish_victim_bootless_again" in fish_victim.default_lines:
			fish_victim.default_lines = [&"fish_victim_defeat"]
		elif &"fish_victim_defeat" in fish_victim.default_lines:
			pass
		else:
			if DAT.get_data("fish_fought", false):
				fish_victim.default_lines = [&"fish_victim_after_fight", &"fish_victim_3"]
	)


func _car_scared_setup() -> void:
	if not DAT.get_data("car_scared_overrun", false):
		$Fishermen/Fisherman33.queue_free()


func _on_fisherwoman_inspected() -> void:
	var dbox := SOL.dialogue_box as DialogueBox
	dbox.dial_concat("fisherwoman_talk_lake", 3, [DAT.get_data("fishing_high_score")])
	dbox.dial_concat("fisherwoman_talk_lake", 4, [roundi(
			DAT.get_data("fishing_max_depth", 0.0) * 0.01)])
	dbox.dial_concat("fisherwoman_talk_lake", 5, [DAT.get_data("fish_caught")])
