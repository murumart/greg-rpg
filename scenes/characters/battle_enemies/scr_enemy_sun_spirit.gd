extends BattleEnemy

@export var mod_gradient : Gradient
@export var size_curve : Curve
@export var music_pitch_curve : Curve

var dead := false


func _ready() -> void:
	super._ready()


func color(amt: float) -> void:
	amt = 1 - amt
	$Puppet/Pivot.modulate = mod_gradient.sample(amt)
	$Puppet/Pivot.scale.x = size_curve.sample(amt)
	character.attack = remap(amt, 0.0, 1.0, 35, 85)
	character.defense = remap(amt, 0.0, 1.0, 85, 20)
	character.speed = remap(amt, 0.0, 1.0, 55, 20)
	SND.current_song_player.pitch_scale = music_pitch_curve.sample(amt)


func ai_action() -> void:
	super.ai_action()
	hurt(2)


func hurt(amt: float) -> void:
	if dead: return
	super.hurt(amt)
	color(character.health_perc())
	if character.health_perc() <= 0.05:
		SOL.vfx("star_nebula")
		super.hurt(3000)
		dead = true
		await get_tree().create_timer(0.5).timeout
		SND.play_song("")


func heal(amt: float) -> void:
	if dead: return
	super.heal(amt)
	color(character.health_perc())


