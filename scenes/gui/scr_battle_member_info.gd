extends Panel
class_name PartyMemberInfoPanel

@onready var portrait = $Portrait
@onready var name_label := $Name
@onready var effect_center := $EffectCenter
@onready var health_bar := $HealthBar
@onready var magic_bar := $MagicBar
@onready var wait_bar := $WaitBar
@onready var remote_transform := $RemoteTransform


func update(actor: BattleActor) -> void:
	var charc := actor.character
	portrait.modulate = actor.modulate
	portrait.modulate.a = 1.0
	portrait.texture = charc.portrait
	name_label.text = str(charc.name)
	health_bar.max_value = charc.max_health
	health_bar.value = charc.health
	magic_bar.max_value = charc.max_magic
	magic_bar.value = charc.magic
	wait_bar.max_value = 1.0
	wait_bar.value = actor.wait
	remote_transform.position = Vector2(12, 12)
	if charc.health <= 0.0:
		portrait.modulate.a = 0.5
