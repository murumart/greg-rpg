extends Area2D

const Menacing = preload("res://scenes/vfx/x_menacing.gd")

@onready var to_white: ColorRect = $ToWhite
@export var menacing: Menacing

var _done: bool:
	set(to): DAT.set_data("x_chase_done", to)
	get: return DAT.get_data("x_chase_done", false)

func _ready() -> void:
	remove_child(to_white)
	SOL.add_ui_child(to_white)
	body_entered.connect(func(grg: PlayerOverworld) -> void:
		if _done:
			return
		_done = true
		DAT.capture_player("cutscene")
		grg.animate("walk_right", true)
		menacing.phase = Menacing.Phase.NONE
		var dist := 480.0
		var time := dist / (grg.SPEED / 60.0)
		var tw := create_tween()
		tw.tween_property(grg, ^"global_position", grg.global_position + Vector2(dist, 0), time)
		tw.parallel().tween_property(to_white, ^"color", Color.WHITE, time)
		if is_instance_valid(SND.current_song_player):
			tw.parallel().tween_property(SND.current_song_player, ^"volume_linear", 0.05, time)
		tw.tween_callback(func() -> void:
			DAT.free_player("cutscene")
			LTS.gate_id = &"sg-p-31"
			LTS.level_transition(LTS.ROOM_SCENE_PATH % "sg_p_1", {start_color = Color.TRANSPARENT, end_color = Color.WHITE})
		)
	)
