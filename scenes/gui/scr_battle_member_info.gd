extends Panel
class_name PartyMemberInfoPanel

@onready var portrait = $Portrait
@onready var name_label := $Name
@onready var effect_center := $EffectCenter
@onready var health_bar := $HealthBar
@onready var magic_bar := $MagicBar
@onready var wait_bar := $WaitBar
@onready var effects_container := $EffectsContainer
@onready var remote_transform : RemoteTransform2D = $RemoteTransform


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
	#remote_transform.position = Vector2(12, 12)
	if charc.health <= 0.0:
		portrait.modulate.a = 0.5
	effects_display(actor)


func effects_display(actor: BattleActor) -> void:
	for i in effects_container.get_children():
		i.queue_free()
	for e in actor.status_effects.keys():
		var effect : Dictionary = actor.status_effects[e]
		if effect.is_empty(): continue
		var rect := TextureRect.new()
		rect.texture = AtlasTexture.new()
		rect.texture.atlas = preload("res://sprites/gui/spr_effects.png")
		rect.texture.region = StatusEffect.ICONS.get(e, Rect2(18, 0, 6, 6))
		effects_container.add_child(rect)
		if effect.duration <= 1:
			rect.modulate = Color(1, 1, 1, 0.75)
		if effect.strength < 0:
			rect.flip_v = true
	
