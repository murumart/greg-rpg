extends Node2D

const Ballgame := preload("res://scenes/circus/ball_popping_minigame.tscn")

@onready var ringleader: OverworldCharacter = $Ringleader
@onready var clown: OverworldCharacter = $Clown
@onready var animal: OverworldCharacter = $Animal
@onready var troupe_kid: CharacterBody2D = $TroupeKid
@onready var members := [ringleader, clown, animal, troupe_kid]
@onready var inter_members := [ringleader, clown, troupe_kid]
@onready var caged_animal: OverworldCharacter = $Animal/CagedAnimal

@onready var other_kids := [get_node_or_null("../../Houses/NeighbourHouse/KidEncounter"),
	get_node_or_null("../../Houses/Skatepark/Goodness/KidOverworld"),
	get_node_or_null("../CampfireSite/CampsiteKid")]

@export var greg: PlayerOverworld
var greg_parent: Node = null
var last_music := String()


func _ready() -> void:
	if not Math.inrange(ResMan.get_character("greg").level, 50, 60):
		queue_free()
		return
	for x in other_kids:
		if is_instance_valid(x):
			x.queue_free()
	var can_teleport: bool = sin(DAT.get_data("nr", 0) * 16.0) < 0.0
	if can_teleport:
		for member: OverworldCharacter in members:
			member.cannot_reach_target.connect(_cannot_reach_target.bind(member))
	clown.inspected.connect(_clown_inspected)
	for member: OverworldCharacter in inter_members:
		member.inspected.connect(_stop_moving)


func _clown_inspected() -> void:
	SOL.dialogue_closed.connect(func():
		if SOL.dialogue_choice == &"play":
			if DAT.get_data("silver", 0) >= 65:
				DAT.incri("silver", -65)
				last_music = SND.current_song_key
				var ballgame := Ballgame.instantiate()
				ballgame.finished.connect(_ballgame_finished)
				SOL.add_ui_child(ballgame)
				ballgame.start()
				greg_parent = greg.get_parent()
				greg_parent.remove_child(greg)
				greg.set_collision_layer_value(2, false)
				greg.set_collision_mask_value(1, false)
				greg.set_collision_mask_value(4, false)
				animal.add_child(greg, true)
				greg.global_position = caged_animal.global_position
				caged_animal.hide()
			else:
				SOL.dialogue("clown_missing_silver")
	, CONNECT_ONE_SHOT)


func _stop_moving() -> void:
	for member: OverworldCharacter in members:
		member.speed = 0
	SOL.dialogue_closed.connect(func():
		for member: OverworldCharacter in members:
			member.speed = 3500
	, CONNECT_ONE_SHOT)


func _ballgame_finished() -> void:
	animal.remove_child(greg)
	greg_parent.add_child(greg, true)
	greg.global_position = caged_animal.global_position
	caged_animal.show()
	greg.set_collision_layer_value(2, true)
	greg.set_collision_mask_value(1, true)
	greg.set_collision_mask_value(4, true)
	SND.play_song(last_music)


func _cannot_reach_target(who: OverworldCharacter) -> void:
	if not is_instance_valid(who.chase_target):
		return
	var tw := create_tween()
	SND.play_sound_2d(preload("res://sounds/teleport.ogg"),
			who.chase_target.global_position,
			{"pitch_scale": randf_range(0.9, 1.2)})
	tw.tween_property(who, "global_position", who.chase_target.global_position, 0.1)
