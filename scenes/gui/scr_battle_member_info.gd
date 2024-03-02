extends Panel
class_name PartyMemberInfoPanel

@onready var portrait = $Portrait
@onready var name_label := $Name
@onready var effect_center := $EffectCenter
@onready var health_bar := $HealthBar
@onready var magic_bar := $MagicBar
@onready var wait_bar := $WaitBar
@onready var animal_bar: ProgressBar = $AnimalBar

@onready var effects_container := $EffectsContainer
@onready var remote_transform: RemoteTransform2D = $RemoteTransform


func update(actor: BattleActor) -> void:
	var charc := actor.character
	portrait.modulate = actor.modulate
	portrait.modulate.a = 1.0
	portrait.texture = charc.portrait
	portrait.scale = Vector2.ONE
	if actor.has_status_effect(&"little"):
		portrait.scale = Vector2(0.5, 0.5)
	name_label.text = str(charc.name)
	health_bar.max_value = charc.max_health
	health_bar.value = charc.health
	magic_bar.max_value = charc.max_magic
	magic_bar.value = charc.magic
	wait_bar.max_value = 1.0
	wait_bar.value = 1 - actor.wait
	animal_bar.visible = actor is EnemyAnimal
	if actor is EnemyAnimal:
		animal_bar.value = actor.soul
	#remote_transform.position = Vector2(12, 12)
	if charc.health <= 0.0:
		portrait.modulate.a = 0.5
	effects_display(actor)


func effects_display(actor: BattleActor) -> void:
	for i in effects_container.get_children():
		effects_container.remove_child(i)
		i.queue_free()
	for e: BattleStatusEffect in actor.status_effects.values():
		var type := e.type
		var rect := TextureRect.new()
		rect.texture = type.icon
		rect.flip_v = e.strength < 0
		effects_container.add_child(rect)
