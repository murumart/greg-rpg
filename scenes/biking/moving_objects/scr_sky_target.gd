extends BikingObstacle

@onready var blow_area: Area2D = $BlowArea


func _ready() -> void:
	$Skew/TargetSprite.rotation = randf_range(-TAU, TAU)
	add_to_group("snail_lasers")


func shake(amount: float) -> void:
	SOL.shake(amount)


func play_beam() -> void:
	$AnimationPlayer.play("beam")
	for ob in blow_area.get_overlapping_areas():
		if ob.get_meta("log", false):
			var olog := ob.get_parent() as Node2D
			var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			var dist := global_position.distance_to(olog.global_position)
			var moveto := olog.global_position.move_toward(global_position, minf(-20.0 + dist, -10.0))
			tw.tween_property(olog, "global_position", moveto, 0.2)
