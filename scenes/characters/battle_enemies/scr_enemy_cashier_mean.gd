extends BattleEnemy

@onready var particles: GPUParticles2D = $GPUParticles2D
var wli_spirit := ResMan.get_spirit("wli_attack") as Spirit
const BackgroundType := preload("res://scenes/battle_backgrounds/scr_battle_background.gd")
const CameraType := preload("res://scenes/tech/scr_camera.gd")
var background: BackgroundType
var camera: CameraType
var dbox := SOL.dialogue_box as DialogueBox
@onready var sprite: Sprite2D = $Sprite2D
@onready var overlay: AudioStreamPlayer = $Overlay


func _ready() -> void:
	super()
	character.speed = maxf(character.speed, ResMan.get_character("greg").speed)
	if "background_container" in LTS.get_current_scene():
		background = LTS.get_current_scene().background_container.get_child(0) as BackgroundType
	if "camera" in LTS.get_current_scene():
		camera = LTS.get_current_scene().camera


func _physics_process(_delta: float) -> void:
	particles.modulate.a = remap(character.magic, 0, 100, 0.0, 1.0)


func act() -> void:
	if character.magic < wli_spirit.cost or character.health_perc() <= 0.1:
		SOL.dialogue("cashier_fight_standstill")
		create_tween().tween_property(SND.current_song_player, "pitch_scale", 0.94, 2.0)
		dbox.started_speaking.connect(_stdst_bits)
		return
	super()


func hurt(amt: float, g: int) -> void:
	var after_this := character.health - _hurt_damage(amt, g)
	if (after_this < 0):
		amt += (character.health - amt) - character.max_health * 0.1
		DAT.set_data("cashier_defeated_thru_damage", true)
	super(amt, g)


func _stdst_bits(line: int) -> void:
	if line == 6:
		dbox.started_speaking.disconnect(_stdst_bits)
		var tw := create_tween()
		var time := 3.0
		if camera:
			tw.parallel().tween_property(camera, "zoom", Vector2(1.5, 1.5), time)
		if background:
			tw.parallel().tween_property(background, "modulate", Color.from_hsv(1.0, 1.0, 10.0, 2.0), time)
		tw.parallel().tween_property(sprite, "scale:x", 1.5, time)
		tw.parallel().tween_property(SND.current_song_player, "pitch_scale", 2.0, time)
		tw.tween_callback(func():
			if SOL.dialogue_open:
				dbox.close()
			SND.play_song("ac_scary", 1000, {start_volume = 0.0})
			camera.zoom = Vector2.ONE
			sprite.texture = preload("res://sprites/characters/battle/cashier_mean/spr_kneel.png")
			particles.texture = preload("res://sprites/characters/battle/cashier_mean/spr_kneel.png")
			sprite.scale.x = 1.0
			overlay.play(wrapf(SND.get_music_playback_position(), 0.0, 12.0))
			var wli := SOL.vfx("wli", Vector2.ZERO) as Node2D
			wli.scale = Vector2(0.1, 0.1)
			wli.modulate.a = 0.0
			wli.z_index = -2
			for x in 10:
				emit_message("no.")
			tw = create_tween()
			tw.tween_property(background.get_node("ColorRect"), "color", Color.BLACK, 1.0)
			tw.parallel().tween_property(overlay, "volume_db", -6.0, 16.0).from(-80.0)
			tw.parallel().tween_property(wli, "scale", Vector2(1, 1), 16.0)
			tw.parallel().tween_property(wli, "modulate:a", 0.8, 16.0)
			await create_tween().tween_interval(4.0).finished
			SOL.dialogue("cashier_fight_interrupt")
			await SOL.dialogue_closed
			await create_tween().tween_interval(2.0).finished
			SOL.dialogue("cashier_fight_interrupt_2")
			await SOL.dialogue_closed
			await create_tween().tween_interval(2.0).finished
			SOL.dialogue("cashier_fight_interrupt_3")
			await SOL.dialogue_closed
			tw = create_tween()
			tw.tween_property(SND.current_song_player, "pitch_scale", 3.0, 1.0)
			tw.parallel().tween_property(overlay, "pitch_scale", 3.0, 1.0)
			tw.parallel().tween_property(camera, "zoom", Vector2(3, 3), 1.0)
			SOL.fade_screen(Color.TRANSPARENT, Color.WHITE, 0.95, {"free_rect": false})
			tw.finished.connect(func():
				var rtw := get_tree().root.create_tween()
				rtw.tween_property(wli, "modulate:a", 0.0, 2.0)
				rtw.finished.connect(wli.queue_free)
				SOL.fade_screen(Color.WHITE, Color.TRANSPARENT, 4.0, {"kill_rects": true})
				LTS.gate_id = &"exit_cashier_fight"
				LTS.change_scene_to("res://scenes/rooms/scn_room_store.tscn")
			)
		)

