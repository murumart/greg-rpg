extends BattleEnemy

const ATTACK := preload("res://sprites/characters/battle/grandma/spr_attack.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var color_rect: ColorRect = $ColorRect
@onready var hand: Sprite2D = $Sprite2D/Hand

var dlg := DialogueBuilder.new().set_char("grandma")
var attacked := false


func _ready() -> void:
	remove_child(color_rect)
	SOL.add_ui_child(color_rect, 120)
	super._ready()
	dlg.add_line(dlg.ml("let's see what you're made of."))
	dlg.add_line(dlg.ml("how will you fare against this defense- less old lady?"))
	await dlg.speak_choice()
	dlg.reset().set_char("grandma")


func act() -> void:
	if not attacked:
		turn_finished()
		return
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	remove_child(sprite)
	SOL.add_ui_child(sprite)
	tw.tween_property(sprite, ^"position", Vector2(79, 99), 0.2)
	tw.parallel().tween_property(sprite, ^"scale", Vector2.ONE * 2, 0.1)
	tw.tween_property(SND.current_song_player, ^"pitch_scale", 0.92, 0.6)
	tw.tween_callback(SND.play_sound.bind(preload("res://sounds/scary_zoomin.ogg")))
	tw.tween_callback(SND.play_song.bind(""))
	tw.tween_property(sprite, ^"scale", Vector2.ONE * 4, 0.75).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(sprite, ^"position:y", 130, 0.75).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(hand, ^"modulate:a", 1.0, 0.5)
	tw.parallel().tween_property(hand, ^"position", Vector2(-6, -14), 0.75).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(color_rect, ^"color", Color.CRIMSON, 0.75)
	tw.tween_callback(func() -> void:
		LTS.gate_id = &"lol"
		LTS.change_scene_to("res://scenes/rooms/scn_room_grandma_house_inside.tscn")
	)
	#var greg: BattleActor = reference_to_opposing_array[0]
	#message.emit("grandma attacked greg!")
	#sprite.texture = ATTACK
	#for i in 400:
		#greg.hurt(1, Genders.VAST)
		#await get_tree().process_frame
		#sprite.flip_h = not sprite.flip_h
		#if greg.character.health_perc() < 0.1:
			#break
	#SND.play_song("")
	#DAT.set_data("fought_grandma", true)
	#DAT.set_data("intro_progress", 2)
	#LTS.gate_id = LTS.GATE_EXIT_BATTLE
	#await get_tree().create_timer(1.5).timeout
	#LTS.level_transition(LTS.ROOM_SCENE_PATH % "grandma_house_inside")


func hurt(_amt: float, _gnd: int) -> void:
	attacked = true
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	sprite.scale = Vector2(1.2, 0.8)
	SND.play_sound(preload("res://sounds/whoosh.ogg"))
	#SND.play_sound(preload("res://sounds/flee.ogg"))
	SOL.vfx(
		"damage_number",
		get_effect_center(self),
		{text = "miss!", color = Color.WHITE})
	tw.tween_property(sprite, ^"global_position:x", 300, 0.2)


func _item_diploma_used_on() -> void:
	SOL.dialogue("grandma_diploma_use")


func _item_winner_hat_used_on() -> void:
	SOL.dialogue("grandma_winner_hat_use")
