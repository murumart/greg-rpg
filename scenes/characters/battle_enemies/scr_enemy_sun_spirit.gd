extends BattleEnemy

@export var mod_gradient : Gradient
@export var size_curve : Curve


func _ready() -> void:
	super._ready()


func color(amt: float) -> void:
	amt = 1 - amt
	$Puppet/Pivot.modulate = mod_gradient.sample(amt)
	$Puppet/Pivot.scale.x = size_curve.sample(amt)
	character.attack = remap(amt, 0.0, 1.0, 35, 85)
	character.defense = remap(amt, 0.0, 1.0, 85, 20)
	character.speed = remap(amt, 0.0, 1.0, 55, 20)


func hurt(amt: float) -> void:
	super.hurt(amt)
	color(character.health_perc())
	if character.health_perc() <= 0.05:
		SOL.vfx("star_nebula")
		super.hurt(3000)

