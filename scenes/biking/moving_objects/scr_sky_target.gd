extends BikingObstacle


func _ready() -> void:
	$Skew/TargetSprite.rotation = randf_range(-TAU, TAU)


func shake(amount: float) -> void:
	SOL.shake(amount)


func play_beam() -> void:
	$AnimationPlayer.play("beam")
