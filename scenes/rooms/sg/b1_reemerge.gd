extends TileMapLayer

@onready var warner := $Warner
@onready var pantheranim: AnimationPlayer = $OutlineMe/Pantherform/Pantheranim
@onready var pantherform: Node2D = $OutlineMe/Pantherform
@onready var outline_me: CanvasGroup = $OutlineMe

var piuzzle_progress: int:
	set(to): DAT.set_data("sg_b4_piuzzl2_progress", to)
	get: return DAT.get_data("sg_b4_piuzzl2_progress", 0)

var panther_fought: bool:
	set(to): DAT.set_data("sg_b4_multipanther_fought", to)
	get: return DAT.get_data("sg_b4_multipanther_fought", false)


func _ready() -> void:
	if not (piuzzle_progress & 0b11):
		hide()
		$SgCatSnake.queue_free()
		return
	warner.inspected.connect(func() -> void:
		if is_instance_valid(SND.current_song_player):
			pantheranim.play_section("Form", -1, 0.0001)
			create_tween().tween_property(SND.current_song_player, ^"volume_linear", 0.25, 1.0)
		SOL.dialogue_closed.connect(func() -> void:
			DAT.capture_player("cutscene")
			SND.play_sound(preload("res://sounds/owl.ogg"), {pitch_scale = 0.7})
			var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(outline_me, ^"global_position", outline_me.global_position + Vector2(0, -181), 2.0)
			tw.parallel().tween_property(SND.current_song_player, ^"volume_db", -80, 1.0)
			await tw.finished
			pantheranim.play(&"Form")
			await pantheranim.animation_finished
			await Math.timer(0.3)
			LTS.enter_battle(preload("res://resources/battle_infos/multipanther_fight.tres"))
			SND.play_sound(preload("res://sounds/men-01.ogg"))
			DAT.free_player("cutscene")
			panther_fought = true
		, CONNECT_ONE_SHOT)
	)
	if panther_fought:
		warner.queue_free()
	$Block.queue_free()
