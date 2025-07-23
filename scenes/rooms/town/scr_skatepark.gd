extends Node2D

@onready var skate_worry := $SkateWorry as OverworldCharacter
@onready var goodness: Node2D = $Goodness
@onready var jack_2 := $Goodness/Jack2 as OverworldCharacter
@onready var kid: CharacterBody2D = $Goodness/KidOverworld
@onready var thug_spawner_4: EnemySpawner = $ThugSpawner4


func _ready() -> void:
	skatepark_setup()


func skatepark_setup() -> void:
	if not PoliceStation.is_bounty_fulfilled("thugs") or DAT.get_data("hunks_enabled", false):
		goodness.queue_free()
		return
	thug_spawner_4.queue_free()
	skate_worry.default_lines.clear()
	if DAT.get_data("hunks_enabled", false):
		skate_worry.default_lines.append_array(["skate_worry_bad", "skate_worry_3"])
	else:
		skate_worry.default_lines.append_array(["skate_worry_good", "skate_worry_3"])
	jack_2.inspected.connect(func():
		SOL.dialogue_closed.connect(func():
			if SOL.dialogue_choice == "yes":
				LTS.level_transition("res://scenes/skating/skating_minigame.tscn")
				SOL.dialogue_choice = ""
		, CONNECT_ONE_SHOT)
	)
