extends StaticBody2D

const SlidingPuzzleLoad := preload("res://scenes/rooms/forest/sliding_puzzle/sliding_puzzle.tscn")
const ITEM_CHANCES := ForestGenerator.BIN_LOOT

@export var puzzle_size_curve: Curve


func _interactde() -> void:
	var forest_data := DAT.get_data("forest_save", {}) as Dictionary
	var played: bool = forest_data.get(_key(), false)
	if not played:
		_play_game()


func _play_game() -> void:
	var forest_data := DAT.get_data("forest_save", {}) as Dictionary
	forest_data[_key()] = true
	var item_type: StringName = Math.weighted_random(ITEM_CHANCES.keys(), ITEM_CHANCES.values())
	var puzzle := SlidingPuzzleLoad.instantiate()
	DAT.capture_player("sliding_puzzle")
	puzzle.image_texture = ResMan.get_item(item_type).texture
	var level := (DAT.get_data("forest_depth", 0) as int) * 0.01
	puzzle.puzzle_size = roundi(puzzle_size_curve.sample_baked(level))
	SOL.add_ui_child(puzzle)
	puzzle.finished.connect(func(won: bool):
		puzzle.queue_free()
		DAT.free_player("sliding_puzzle")
		if won:
			DAT.grant_item(item_type)
	)


func _key() -> String:
	return "pizzle_column_" + str(DAT.get_data("forest_depth", 0)) + "_played"

