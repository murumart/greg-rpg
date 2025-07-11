extends OverworldCharacter

@onready var pemit: GPUParticles2D = $Sprite/Particles


func sanimate(anim: StringName, aspd := 1.0) -> void:
	if not anim:
		set_physics_process(true)
		return
	set_physics_process(false)
	animated_sprite.speed_scale = aspd
	animated_sprite.play(anim)
	var fsize := animated_sprite.sprite_frames.get_frame_texture(anim, 0).get_size()
	animated_sprite.offset.y = -fsize.y
	pemit.position.y = -fsize.y * 0.5


func tanim_shake(amt: int, strength: float, aspd := 1.0) -> void:
	var tw := animated_sprite.create_tween().set_trans(Tween.TRANS_CUBIC)
	for i in amt:
		var s := (1.0 - i / float(amt)) * strength
		tw.tween_property(animated_sprite, "position:x", -s, 0.01 / aspd)
		tw.tween_property(animated_sprite, "position:x", s, 0.01 / aspd)
	tw.tween_property(animated_sprite, "position:x", 0, 0.01 / aspd)
	await tw.finished


func tanim_bounce(strength: float, aspd := 1.0) -> void:
	var tw := animated_sprite.create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(animated_sprite, "scale", Vector2(1.0 / strength, strength), 0.025 / aspd)
	tw.tween_property(animated_sprite, "scale", Vector2(strength, 1.0 / strength), 0.05 / aspd)
	tw.tween_property(animated_sprite, "scale", Vector2.ONE, 0.05 / aspd)
	await tw.finished


func particles(amt := 0.0, ltime := 1.0, spwidth := 1.0) -> void:
	if amt <= 0:
		pemit.hide()
	else:
		pemit.show()
	pemit.amount_ratio = amt
	pemit.lifetime = ltime
	var pmat := pemit.process_material
	pmat.emission_shape_scale.x = spwidth
