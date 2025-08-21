extends Node2D

const LEVEL_LIMIT := 59
const FOUGHT_KEY := &"fought_woodsguy"
const SEEN_CUTSCENE := &"seen_woodsguy_cutscene"
const GREG := &"greg"

@onready var inspect_area: InspectArea = $InspectArea
@onready var bird_sprite: Sprite2D = $BirdSprite
@onready var woods_guy: OverworldCharacter = $WoodsGuy
@onready var after_battle_position: Marker2D = $AfterBattlePosition
@onready var greg: PlayerOverworld = $"../../Greg"


func _ready() -> void:
	if DAT.get_data(FOUGHT_KEY, false):
		if DAT.get_data(SEEN_CUTSCENE, false):
			queue_free()
		else:
			bird_sprite.queue_free()
			inspect_area.queue_free()
			_cutscene_after()
			DAT.set_data(SEEN_CUTSCENE, true)
		return
	inspect_area.inspected.connect(_inspected)


func _inspected() -> void:
	var lvl := ResMan.get_character(GREG).level

	if lvl < LEVEL_LIMIT:
		SOL.dialogue("insp_blocking_bird_low")
		return

	SOL.dialogue("insp_blocking_bird")
	await SOL.dialogue_closed
	if SOL.dialogue_choice == "yes":
		# the battel
		await _cutscene_before()
		DAT.set_data(FOUGHT_KEY, true)
		LTS.enter_battle(load("res://resources/battle_infos/woods_guy_fight.tres"))


func _cutscene_before() -> void:
	var tw := create_tween()
	DAT.capture_player("cutscene")
	bird_sprite.hide()
	SND.play_song("")
	SOL.vfx("bird_flight", global_position, {"parent": self})
	tw.tween_interval(2.0)
	tw.tween_property(woods_guy, "global_position", global_position, 1.0)
	tw.tween_interval(0.1)
	await tw.finished
	SOL.dialogue("woods_guy_approach")
	await SOL.dialogue_closed
	DAT.free_player("cutscene")


func _cutscene_after() -> void:
	DAT.capture_player("cutscene")
	greg.global_position = after_battle_position.global_position
	woods_guy.global_position = after_battle_position.global_position + Vector2.UP * 12
	greg.animate("walk_up")
	await Math.timer(1.0)
	SOL.dialogue("woods_guy_after_battle")
	await SOL.dialogue_closed
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(woods_guy, ^"global_position:y", woods_guy.global_position.y - 48, 0.8)
	tw.tween_callback(func() -> void:
		DAT.free_player("cutscene")
		queue_free()
	)
