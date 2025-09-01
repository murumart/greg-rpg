extends Node2D

@onready var sg_cat_owl_2 := $SgCatOwl2
@onready var light: Sprite2D = %Light

var dead: bool:
	set(to): DAT.set_data("sgy5deadcat", to)
	get: return DAT.get_data("sgy5deadcat", false)


func _ready() -> void:
	if dead:
		sg_cat_owl_2.queue_free()
		return
	sg_cat_owl_2.inspected.connect(func() -> void:
		SOL.dialogue_closed.connect(func() -> void:
			DAT.capture_player("cutscene")
			var snd := SND.play_sound(preload("res://sounds/snail_quasar.ogg"), {pitch_scale = 1.2})
			var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			light.show()
			tw.tween_property(light, ^"scale:x", 1.0, 0.4).from(0.0)
			await tw.finished
			SOL.vfx("explosion", sg_cat_owl_2.global_position, {parent = self})
			sg_cat_owl_2.queue_free()
			snd.stop()
			dead = true
			light.hide()
			DAT.free_player("cutscene")
		, CONNECT_ONE_SHOT)
	)
