extends BattleEnemy

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
var wli_spirit := DAT.get_spirit("wli_attack") as Spirit
const BackgroundType := preload("res://scenes/battle_backgrounds/scr_battle_background.gd")
const CameraType := preload("res://scenes/tech/scr_camera.gd")
var background: BackgroundType
var camera: CameraType
var dbox := SOL.dialogue_box as DialogueBox
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	if "background_container" in LTS.get_current_scene():
		background = LTS.get_current_scene().background_container.get_child(0) as BackgroundType
	if "camera" in LTS.get_current_scene():
		camera = LTS.get_current_scene().camera


func _physics_process(delta: float) -> void:
	gpu_particles_2d.modulate.a = remap(character.magic, 0, 100, 0.0, 1.0)


func act() -> void:
	if character.magic < wli_spirit.cost or character.health_perc() <= 0.1:
		SOL.dialogue("cashier_fight_standstill")
		dbox.started_speaking.connect(_stdst_bits)
		return
	super()


func hurt(amt: float, g: int) -> void:
	if (character.health - amt) / character.max_health < 0.1:
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
		# TODO rest of the freaking curtscene.

