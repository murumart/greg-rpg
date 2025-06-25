extends Node2D

const LEVEL_LIMIT := 55
const FOUGHT_KEY := "fought_woodsguy"
const GREG := "greg"

@onready var inspect_area: InspectArea = $InspectArea
@onready var bird_sprite: Sprite2D = $BirdSprite
@onready var woods_guy: OverworldCharacter = $WoodsGuy


func _ready() -> void:
	if DAT.get_data(FOUGHT_KEY, false):
		queue_free()
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
