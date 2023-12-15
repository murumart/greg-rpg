extends Room

@onready var background: Sprite2D = $Background
@onready var gradient: Gradient = background.material["shader_parameter/Gradient"].gradient


func _ready() -> void:
	SOL.dialogue_closed.connect(_dialogue_ended)
	SND.play_song("staredown", 100.0)
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	await get_tree().create_timer(2.0).timeout
	SOL.dialogue("grandma_fight_end")


func _dialogue_ended() -> void:
	$AnimationPlayer.play("white_animation")
	await $AnimationPlayer.animation_finished
	LTS.gate_id = "greghouse_inside-outside"
	LTS.level_transition(DIR.room_scene_path("greg_house"))
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
