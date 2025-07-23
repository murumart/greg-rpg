extends Area2D

# that's how mafia works

@onready var mafia_blue: OverworldCharacter = %MafiaBlue
@onready var mafia_yellow: OverworldCharacter = %MafiaYellow
@onready var mafia_1_sprite: AnimatedSprite2D = %"MafiaBlue/AnimatedSprite2D"
@onready var mafia_2_sprite: AnimatedSprite2D = %"MafiaYellow/AnimatedSprite2D"
@onready var greg: PlayerOverworld = $"../../Greg"
@onready var lights: Array[PointLight2D]
@onready var radio: Node2D = $"../../Decorations/Radio"
@onready var big_light: PointLight2D = $"../../Decorations/BigLight"

var introed: bool:
	set(to): DAT.set_data("mafia_introed", to)
	get: return DAT.get_data("mafia_introed", false)


func _ready() -> void:
	lights.assign(get_tree().get_nodes_in_group(&"lights"))
	if introed:
		big_light.show()
	SOL.dialogue("mafia_mumbles_1")


func _to_game() -> ListeningGame:
	radio.musicplayer.stop()
	$AudioStreamPlayer.play()
	for l in lights:
		l.hide()
	var lg := ListeningGame.make(2, 1)
	if not introed:
		lg.tutorialate = true
		await Math.timer(5.0)
	else:
		await Math.timer(1.0)
	SOL.add_ui_child(lg)
	return lg


func _area_entered() -> void:
	DAT.capture_player("cutscene")
	SOL.dialogue("mafia_interrupt")
	var anim := "walk_right" if mafia_1_sprite.global_position.x - greg.global_position.x < -1 else "walk_left"
	mafia_1_sprite.play(anim)
	mafia_2_sprite.play(anim)
	await SOL.dialogue_closed
	var lg := await _to_game()
	var corrects: int = await lg.finished
	if not introed:
		DAT.set_data("mfia_first_corrects", corrects)
	lg.queue_free()
	_after_game()


func _after_game() -> void:
	await Math.timer(1.0)
	for l in lights:
		l.show()
	$AudioStreamPlayer.play()
	greg.global_position = %GregPos.global_position
	mafia_blue.global_position = %MafiaPos.global_position
	mafia_1_sprite.stop()
	mafia_2_sprite.stop()
	mafia_yellow.global_position = %MafiaPos.global_position + Vector2(0, -10)
	greg.animate("walk_down")
	await Math.timer(1.0)
	greg.animate("walk_left")
	await Math.timer(0.5)
	DAT.free_player("cutscene")
	if not introed:
		SOL.dialogue("mafia_after_first")
		await SOL.dialogue_closed
		introed = true
