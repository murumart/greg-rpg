extends StaticBody2D

signal finished

const SlidingPuzzleLoad := preload("res://scenes/rooms/forest/sliding_puzzle/sliding_puzzle.tscn")

@export var puzzle_size_curve: Curve
@export var puzzle_items: Array[KeyCurve] = []

var rewards := BattleRewards.new()
var played: bool:
	get: return DAT.get_data("forest_save", {}).get(_key(), false)
	set(to): DAT.get_data("forest_save", {})[_key()] = to



func _interactde() -> void:
	if played:
		return
	SOL.dialogue("sliding_pizzle_what")
	await SOL.dialogue_closed
	if SOL.dialogue_choice == &"yes":
		_play_game()


func _play_game() -> void:
	played = true

	var puzzle := SlidingPuzzleLoad.instantiate()
	var level := (DAT.get_data("forest_depth", 0) as int) * 0.01
	puzzle.puzzle_size = roundi(puzzle_size_curve.sample_baked(level))
	_pick_item(puzzle)
	DAT.capture_player("sliding_puzzle")
	SOL.add_ui_child(puzzle)
	puzzle.finished.connect(func(won: bool):
		if is_instance_valid(SND.current_song_player):
			var tw := create_tween()
			tw.tween_property(SND.current_song_player, "pitch_scale", 1.0, 2.0)
		puzzle.queue_free()
		DAT.free_player("sliding_puzzle")
		if won:
			rewards.grant(true)
		self.finished.emit()
	)


func _key() -> String:
	return "pizzle_column_" + str(DAT.get_data("forest_depth", 0)) + "_played"


func _pick_item(puzzle: SlidingPuzzle) -> void:
	rewards.clear()
	const ITEM_CHANCES := ForestGenerator.BIN_LOOT
	var level := (DAT.get_data("forest_depth", 0) as int) * 0.01
	var chosen_thing: StringName
	puzzle_items.shuffle()
	for kkp: KeyCurve in puzzle_items:
		if kkp.curve.sample_baked(level) >= randf():
			chosen_thing = kkp.key
			break
	if not chosen_thing:
		chosen_thing = Math.weighted_random(ITEM_CHANCES.keys(), ITEM_CHANCES.values())

	if chosen_thing in ResMan.items:
		puzzle.image_texture = ResMan.get_item(chosen_thing).texture
		var amount := 1
		if chosen_thing in ITEM_CHANCES:
			var wishful_thinking := puzzle.puzzle_size + randi_range(-1, 1)
			amount += randi_range(0,
					mini(roundi(sqrt(ITEM_CHANCES[chosen_thing])), wishful_thinking))
		for a in amount:
			rewards.add(Reward.new({"type": BattleRewards.Types.ITEM,
					"property": str(chosen_thing)}))
	elif chosen_thing == &"kid":
		rewards.add(Reward.new({"type": BattleRewards.Types.GLASS, "property": "15"}))
		puzzle.image_texture = ResMan.get_character(chosen_thing).portrait
	elif chosen_thing == &"greg":
		var greg := ResMan.get_character(chosen_thing)
		puzzle.image_texture = greg.portrait
		rewards.add(Reward.new({"type": BattleRewards.Types.EXP, "property":
				str(randi_range(greg.xp2lvl(greg.level + 1),
				greg.xp2lvl(greg.level + 2)))}))
