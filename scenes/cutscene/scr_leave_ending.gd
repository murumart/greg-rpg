extends Node2D

const DIAL := "

DIALOGUE end_1
	(he dies)

"

@onready var gre: AnimatedSprite2D = $Gre
@onready var ground: TextureRect = $ground
@onready var sky: ColorRect = $sky
@onready var song: AudioStreamPlayer = $song
@onready var forest: TextureRect = $forest
@onready var color_container: ColorContainer = $CanvasModulateGroup/ColorContainer
@onready var bgus: GPUParticles2D = $bgus
@onready var crickets: AudioStreamPlayer = $crickets


func _ready() -> void:
	SOL.dialogue_box.add_dialogue_string(DIAL)
	bgus.emitting = false
	color_container.color = Color.WHITE
	var loops := 18
	var time := 6.0
	var tw := create_tween()
	tw.tween_property(gre, "global_position:x", 74, 2.0)
	var groundtw := create_tween().set_loops(loops)
	groundtw.tween_property(ground, "global_position:x", -269, time).from(0.0)
	tw.parallel().tween_property(forest, "global_position:x", -230, loops * time)
	tw.parallel().tween_property(song, "pitch_scale", 0.96, loops * time)
	gre.play("walk_right")
	await tw.finished
	gre.play("walk_right", 0.0)
	tw = create_tween()
	tw.tween_property(song, "pitch_scale", 0.99, 3.0)
	await tw.finished
	song.stop()
	tw = create_tween()
	crickets.play()
	tw.tween_property(color_container, "color", Color("#13336a"), 4.0)
	tw.parallel().tween_property(crickets, "volume_db", -16, 4.0)
	tw.parallel().tween_property(forest.material, "shader_parameter/amount", 1.0, 4.0)
	tw.tween_callback(bgus.set_emitting.bind(true))
	await tw.finished
	await Math.timer(10.0)
	SOL.dialogue("end_1")
	await SOL.dialogue_closed
	var e: Array = DIR.gej(3, [])
	e.append(2)
	DIR.sej(3, e)
	LTS.level_transition("res://scenes/gui/scn_main_menu.tscn")

