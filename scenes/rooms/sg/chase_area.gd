extends Area2D

const Menacing = preload("res://scenes/vfx/x_menacing.gd")
const Wall = preload("res://scenes/rooms/sg/evil_fucking_wall.gd")

@export var menacing: Menacing
@export var wall: Wall

var _chase_on: bool
var _done: bool:
	set(to): DAT.set_data("x_chase_done", to)
	get: return DAT.get_data("x_chase_done", false)


func _ready() -> void:
	body_entered.connect((func(body: PlayerOverworld) -> void:
		if _chase_on or _done:
			return
		DAT.death_reason = DAT.DeathReasons.X
		body.saving_disabled = true
		_chase_on = true
		menacing._delay = 4.0
		menacing.global_position = body.global_position - Vector2(0, 32)
		menacing.modulate.a = 0.0
		DAT.capture_player("cutscene")
		var deaths: int = DAT.get_data("deaths", []).count(int(DAT.DeathReasons.X))
		if deaths == 0:
			SOL.dialogue("phone_before_xchase_nodeaths")
		elif deaths < 2:
			SOL.dialogue("phone_before_xchase_yesdeaths")
		else:
			SOL.dialogue("phone_before_xchase_moredeaths")

		await SOL.dialogue_closed
		SND.play_song("")
		menacing.blare_sound.play()
		body.animate("walk_up")
		var tw := create_tween()
		tw.tween_property(menacing, ^"modulate:a", 1.0, 1.0).from(0.0)
		tw.tween_interval(0.3)
		await tw.finished
		DAT.free_player("cutscene")
		SND.play_song("xchase", 99, {pitch_scale = 0.89})
		menacing.move_mode = Menacing.MoveMode.FOLLOW
		menacing.phase = Menacing.Phase.SHOOT
		wall.activate()
	))
