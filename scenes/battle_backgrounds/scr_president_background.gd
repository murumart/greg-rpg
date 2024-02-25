extends Node2D

@export var spin_speed := 155
@onready var beam := $Lighthouse/Beam as Sprite2D
var beam_direction := 1.0
@onready var mus_bar_counter: MusBarCounter = $MusBarCounter
@onready var spin_pivot: Node2D = $Lighthouse/SpinPivot
@onready var mist_2: GPUParticles2D = $Mist2
@onready var mist: GPUParticles2D = $Mist
@onready var text_box: TextBox = $TextBox
var initial_message_spoken := false


func _ready() -> void:
	SOL.dialogue_open = true
	SOL.fade_screen(Color.WHITE, Color.TRANSPARENT, 3.0)
	if LTS.get_current_scene().name == "Battle":
		LTS.get_current_scene().ui.modulate.a = 0.0
	mus_bar_counter.new_bar.connect(new_bar)
	mist.modulate.a = 0.0
	mist_2.modulate.a = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mist, "modulate:a", 1.0, 6.0)
	tw.parallel().tween_property(mist_2, "modulate:a", 1.0, 6.0)
	tw.tween_interval(5)
	tw.tween_property(beam, "modulate:a", 1.0, 0.6)


func _physics_process(delta: float) -> void:
	beam.scale.x += delta * spin_speed * (1 / 60.0) * beam_direction
	if beam.scale.x >= 2.0 or beam.scale.x <= -2.0:
		beam_direction *= -1
	beam.self_modulate.a = remap(absf(beam.scale.x), 0.0, 2.0, 0.1, 1.1)
	spin_pivot.rotation += spin_speed * delta * (1 / 60.0)
	spin_pivot.get_children().map(func(a: OverworldCharacter):
		a.global_rotation = 0.0
		a.direct_walking_animation(a.global_position.direction_to(spin_pivot.global_position))
	)


func new_bar(bar) -> void:
	if not initial_message_spoken:
		if bar == 1:
			text_box.text = "my name is president frankling. i rule over the mighty country of beacon archipelago. "
			text_box.speak_text({"speed": 2.5})
		elif bar == 4:
			text_box.text = "i am endeared to my citizens, for i am a just and brilliant ruler."
			text_box.speak_text({"speed": 2.5})
		elif bar == 6:
			text_box.text = "it is i who establishes justice, and you, young man, have brought upon me great injustice."
			text_box.speak_text({"speed": 2.5})
			var tw := create_tween()
			tw.tween_property(spin_pivot, "modulate:a", 1.0, 2.0)
			if LTS.get_current_scene().name == "Battle":
				tw.tween_property(
						LTS.get_current_scene().ui, "modulate:a", 1.0, 1.0
						).set_trans(Tween.TRANS_BOUNCE)
		elif bar == 9:
			var tw := create_tween()
			tw.tween_property(
					text_box, "theme_override_colors/font_outline_color",
					Color(Color.DARK_MAGENTA, 0.3), 1.0)
			text_box.text = "thus, i demand reparations.

you'll find my demands
	convincing and fair."
			text_box.speak_text({"speed": 3.5})
		elif bar == 13:
			SOL.dialogue_open = false
			var tw := create_tween()
			tw.tween_property(spin_pivot, "modulate:a", 0.0, 2.0)
			text_box.text = ""
			initial_message_spoken = true
