extends Node2D

# bikes that can be used for fast travel 
# (eventually)

enum Ghosts {ALPHA, BETA, GAMMA}
const G_DIAL_PREXES = {
	Ghosts.ALPHA: "bike_ghost_",
}
const DIAL_AFTER_DEFEAT := "afterdefeat"
const DIAL_TRAVEL := "travel"
const DIAL_TRAVEL_OPTIONS := "travel_options"
const DIAL_TRAVEL_NODESTS := "travel_nodests"

@onready var interaction_area: InteractionArea = $InteractionArea
@onready var collision: StaticBody2D = $StaticBody2D

@export var ghost: Ghosts = Ghosts.ALPHA

@export var alpha_battle_info: BattleInfo


func _ready() -> void:
	load_ghosts()


func apply_spawn_point(player: PlayerOverworld) -> void:
	if LTS.gate_id == LTS.GATE_BIKE_TRAVEL:
		player.global_position = $SpawnPoint.global_position


func _interacted() -> void:
	var fought: Array = DAT.get_data("bike_ghosts_fought", [])
	if ghost == Ghosts.ALPHA and not Ghosts.ALPHA in fought:
		SND.play_song("")
		SOL.dialogue("bike_alpha_interact_1")
		SOL.dialogue_closed.connect( 
			func():
				DAT.capture_player("cutscene")
				$AnimationPlayer.play("emerge")
				SND.play_song("bike_spirit", 0.20, {pitch_scale = 0.75, volume = -5})
				SND.play_sound(load("res://sounds/spirit/bikeghost/alpha_appear.ogg"), {bus = "ECHO"})
				await get_tree().create_timer(2.0).timeout
				SOL.dialogue("bike_alpha_interact_2")
				SOL.dialogue_closed.connect(
					func():
						DAT.free_player("cutscene")
						LTS.enter_battle(alpha_battle_info)
				)
		, CONNECT_ONE_SHOT)
		return
	SOL.dialogue(G_DIAL_PREXES[ghost] + DIAL_AFTER_DEFEAT)
	await SOL.dialogue_closed
	if SOL.dialogue_choice == &"travel":
		if fought.size() > 1:
			SOL.dialogue(G_DIAL_PREXES[ghost] + DIAL_TRAVEL_OPTIONS)
			SOL.dialogue_closed.connect(func():
				if SOL.dialogue_choice != &"nvm":
					pass
			, CONNECT_ONE_SHOT)
		else:
			SOL.dialogue(G_DIAL_PREXES[ghost] + DIAL_TRAVEL_NODESTS)


func load_ghosts() -> void:
	if not int(Ghosts.ALPHA) in DAT.get_data("bike_ghosts_fought", []):
		pass
