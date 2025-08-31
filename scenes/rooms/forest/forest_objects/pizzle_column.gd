extends "res://scenes/rooms/forest/forest_objects/scr_puzzle_column.gd"

const SlidingPuzzleLoad := preload("res://scenes/rooms/forest/sliding_puzzle/sliding_puzzle.tscn")

@export_group("Forest")
@export var puzzle_size_curve: Curve
@export var puzzle_items: Array[KeyCurve] = []

@export_group("Custom", "custom_")
@export_range(-1, 5) var custom_puzzle_size := -1
@export var custom_puzzle_reward: Resource
@export var custom_puzzle_image: Texture
@export var custom_finished: bool:
	set(to): DAT.set_data(_key_custom() + "finished", to)
	get: return DAT.get_data(_key_custom() + "finished", false)

var rewards := BattleRewards.new()
var puzzle: Node


func _ready() -> void:
	super()
	assert(custom_puzzle_reward == null or custom_puzzle_reward is Item or custom_puzzle_reward is Spirit)
	if custom_finished:
		active = true
		return
	puzzle = SlidingPuzzleLoad.instantiate()
	var level: float = (DAT.get_data("forest_depth", 0)) * 0.01
	puzzle.puzzle_size = roundi(puzzle_size_curve.sample_baked(level)) if custom_puzzle_size == -1 else custom_puzzle_size
	_pick_item(puzzle, level)


func _exit_tree() -> void:
	if is_instance_valid(puzzle):
		puzzle.queue_free()


func _interacted() -> void:
	if active:
		return
	SOL.dialogue("sliding_pizzle_what")
	$AudioStreamPlayer.play()
	await SOL.dialogue_closed
	if SOL.dialogue_choice == &"yes":
		_play_game()


func _play_game() -> void:
	$AudioStreamPlayer.play()
	DAT.capture_player("sliding_puzzle")
	SOL.add_ui_child(puzzle)
	puzzle.request_ready()
	puzzle.finished.connect(func(won: bool):
		if is_instance_valid(SND.current_song_player):
			var tw := create_tween()
			tw.tween_property(SND.current_song_player, "pitch_scale", 1.0, 2.0)
		SOL.remove_ui_child(puzzle)
		DAT.free_player("sliding_puzzle")
		if won:
			rewards.grant(true)
			if custom_puzzle_size != -1:
				custom_finished = true
			active = true
			self.finished.emit()
	, CONNECT_ONE_SHOT)


func _pick_item(puzzle: SlidingPuzzle, level: float) -> void:
	rewards.clear()
	if custom_puzzle_reward:

		if custom_puzzle_reward is Item:
			rewards.add(Reward.new()
				.stype(BattleRewards.Types.ITEM)
				.sproperty(custom_puzzle_reward.name_in_file))

			puzzle.image_texture = custom_puzzle_reward.texture
		elif custom_puzzle_reward is Spirit:
			rewards.add(Reward.new()
				.stype(BattleRewards.Types.SPIRIT)
				.sproperty(custom_puzzle_reward.name_in_file))

		if custom_puzzle_image:
			puzzle.image_texture = custom_puzzle_image
		return
	const ITEM_CHANCES := ForestGenerator.BIN_LOOT
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


static func _kn() -> String:
	return "pizzle_column"


func _key_custom() -> StringName:
	return _kn() + "_in_" + LTS.get_current_scene().name + "_"
