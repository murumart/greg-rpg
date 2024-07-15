extends Node2D

@onready var guru: OverworldCharacter = $StatusEffectGuru
@onready var tarikas: OverworldCharacter = $Tarikas


func _ready() -> void:
	tarikas.inspected.connect(_on_tarikas_inspected)
	tarikas_lines()
	if DAT.get_data("battles", 0) < 3:
		pass
		guru.queue_free()


func tarikas_lines() -> void:
	var level := ResMan.get_character("greg").level
	var lines_to_set: Array[StringName] = []
	tarikas.convo_progress = 0
	if not DAT.get_data("tarikas_talked_to", false):
		lines_to_set.append("tarikas_hello")
	if level < 5:
		pass
	elif Math.inrange(level, 6, 10):
		lines_to_set.append("tarikas_10")
	elif Math.inrange(level, 11, 15):
		lines_to_set.append("tarikas_15")
	elif Math.inrange(level, 16, 25):
		if DAT.get_data("biking_games_finished", 0) > 0:
			lines_to_set.append("tarikas_25")
	elif Math.inrange(level, 26, 35):
		lines_to_set.append("tarikas_30")
	elif level == 36:
		lines_to_set.append("tarikas_36")
	elif Math.inrange(level, 37, 49):
		if DAT.get_data("fulfilled_bounty_thugs", false):
			lines_to_set.append("tarikas_40_nothugs")
		else:
			if DAT.get_data("met_tarikas_beyond_lake", false):
				lines_to_set.append("tarikas_40_met")
			else:
				if Math.inrange(level, 45, 49):
					if DAT.get_data("witnessed_ushanka_guy_cutscene", false):
						lines_to_set.append("tarikas_45")
				else:
					lines_to_set.append("tarikas_40_nomeet")

	elif Math.inrange(level, 50, 59):
		if not DAT.get_data("vampire_defeated", false):
			lines_to_set.append("tarikas_50_nomail")
		else:
			lines_to_set.append("tarikas_50")
	elif Math.inrange(level, 60, 69):
		lines_to_set.append("tarikas_60")
	elif Math.inrange(level, 70, 79):
		lines_to_set.append("tarikas_70")
	lines_to_set.append("tarikas_finish")
	tarikas.default_lines = lines_to_set

func _on_tarikas_inspected() -> void:
	DAT.set_data("tarikas_talked_to", true)

