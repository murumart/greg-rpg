extends BattleEnemy

@export var mod_gradient: Gradient
@export var size_curve: Curve
@export var music_pitch_curve: Curve

var nova := 0.0
@onready var nova_prospect := $NovaProspect

var dead := false


func _ready() -> void:
	remove_child(nova_prospect)
	SOL.add_ui_child(nova_prospect)
	super._ready()
	nova_process(0)
	color(character.health_perc())


func color(amt: float) -> void:
	amt = 1 - amt
	$Puppet/Pivot.modulate = mod_gradient.sample(amt)
	$Puppet/Pivot.scale.x = size_curve.sample(amt)
	character.attack = remap(amt, 0.0, 1.0, 35, 85)
	character.defense = remap(amt, 0.0, 1.0, 69, 20)
	character.speed = remap(amt, 0.0, 1.0, 55, 20)


func ai_action() -> void:
	hurt(2, Genders.FLAMING)
	super.ai_action()


func hurt(amt: float, gnd: int) -> void:
	if dead:
		return
	var oldhp := character.health
	super(amt, gnd)
	color(character.health_perc())
	if character.health_perc() <= 0.05:
		if nova < 0.99:
			nova = -2000
			SOL.vfx("star_nebula")
			super.hurt(3000, Genders.VAST)
			dead = true
			DAT.set_data("solar_protuberance_defeated", true)
	var change := absf(character.health - oldhp)
	nova_process(pow(change * 1.01, 1.35) / character.max_health)


func heal(amt: float) -> void:
	if dead: return
	super.heal(amt)
	color(character.health_perc())
	nova_process(-(amt / character.max_health) * 6)


# couldn't think of a better pun with Nova Prospekt
# but I named the node that nice
func nova_process(add: float) -> void:
	var old_nova := nova
	nova += add
	var tw1 := create_tween()
	var tw2 := create_tween()
	tw1.tween_property(nova_prospect.get_child(0), "value", nova, 0.5)
	var col := Color.RED
	if nova < old_nova:
		col = Color.GREEN
	tw2.tween_property(nova_prospect.get_child(0), "modulate", col, 0.5)
	tw2.tween_property(nova_prospect.get_child(0), "modulate", Color.WHITE, 0.5)
	if is_instance_valid(SND.current_song_player):
		SND.current_song_player.pitch_scale = music_pitch_curve.sample(nova)
	if nova >= 0.99:
		if absf(nova) < 200:
			nova = 200
			use_spirit("nova", self)
			SND.play_song("", 300)
			DAT.death_reason = "nova"


func _used_spirit_flare() -> void:
	heal(10)
