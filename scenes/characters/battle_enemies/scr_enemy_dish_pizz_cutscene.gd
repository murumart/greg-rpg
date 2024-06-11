extends Node2D

@onready var president: Sprite2D = $President
@onready var pizz_guy: Sprite2D = $PizzaGuy
@onready var pizz_powerline: Node2D = $PizzaGuy/VfxPowerline
@onready var pizz_beam: Sprite2D = $PizzaGuy/Sprite2D

@onready var pizz_animation: AnimationPlayer = $Node2D/Pizzabox/PizzAnimation
@onready var pizz_node: Node2D = $Node2D


func animate() -> void:
	var tw := create_tween()
	tw.tween_property(president, "global_position:x", -40, 2.0)
	tw.tween_callback(func(): SOL.dialogue("president_pizz_1"))
	SOL.dialogue_closed.connect(func():
		SND.play_song("", 1272)
		SND.play_sound(preload("res://sounds/pizz_arrive.ogg"))
		pizz_guy.global_position.x = 40
		pizz_powerline.show()
		pizz_guy.scale.x = 0.0
		SOL.shake(2.0)
		tw = create_tween()
		tw.tween_property(pizz_guy, "scale:x", 1.0, 0.1)
		tw.parallel().tween_property(pizz_powerline, "line_width", 0.0, 1.0)
		tw.parallel().tween_property(pizz_beam, "scale:x", 0.2, 1.3)
		tw.parallel().tween_property(pizz_beam, "modulate:a", 0.0, 1.2)
		tw.tween_callback(func():
			pizz_powerline.hide()
			tw = create_tween()
			tw.tween_interval(0.5)
			tw.tween_callback(func(): SOL.dialogue("president_pizz_2"))
			SOL.dialogue_closed.connect(func():
				pizz_animation.play("pizz")
				pizz_animation.animation_finished.connect(func(_a):
					SOL.dialogue("president_pizz_3")
					await SOL.dialogue_closed
					SND.play_sound(preload("res://sounds/spirit/dish_cannon.ogg"))
					LTS.change_scene_to("res://scenes/gui/scn_death_screen.tscn")
				)
			, CONNECT_ONE_SHOT)
		)
	, CONNECT_ONE_SHOT)

