class_name StatusEffectType extends Resource

@export var s_id := &""

@export var name := ""
@export var icon: Texture2D
@export var turn_payload: StatusEffectPayload

@export_group("Metainfo")
@export var color := Color.WHITE
@export_enum(
	"None", "Electric",
	"Sopping", "Burning",
	"Ghost", "Brain", "Vast"
	) var gender: int
@export var use: Spirit.Uses
@export var cost := 5
@export var turn_visual := &""
@export var process_visual := &""
@export var turn_script: GDScript
@export var hurt_response_script: GDScript
@export var added_script: GDScript
@export var removed_script: GDScript
@export_range(0.0, 0.1, 0.001) var process_visual_chance := 0.005
@export var turn_sound: AudioStream


func turn(actor: BattleActor, container: BattleStatusEffect) -> void:
	if turn_script:
		turn_script.new().turn(actor, container)
	if turn_payload:
		await actor.handle_payload(turn_payload.get_payload_b(container))
	if turn_visual:
		SOL.vfx(turn_visual, actor.get_effect_center() + SOL.SCREEN_SIZE / 2 +
			Vector2(randf_range(-2, 2), randf_range(-2, 2)), {"parent": actor})
	if turn_sound:
		SND.play_sound(turn_sound)


func actor_hurt_response(actor: BattleActor, container: BattleStatusEffect, attack_gender: int, damage_amount: float) -> float:
	var amt := damage_amount
	if Genders.CIRCLE[attack_gender] == gender:
		amt *= 1.1
	if hurt_response_script:
		var c = hurt_response_script.new()
		if c.has_method(&"hr"):
			amt += c.hr(actor, container, attack_gender, amt)
		else:
			printerr("no mehod")
	return amt - damage_amount


func process_visuals(actor: BattleActor, _container: BattleStatusEffect) -> void:
	if process_visual and randf() < process_visual_chance:
		SOL.vfx(process_visual,
				actor.get_effect_center() + Vector2(randf_range(-4, 4),
				randf_range(-8, 16)), {"parent": actor})
	if randf() < process_visual_chance:
		var tw := actor.create_tween().set_trans(Tween.TRANS_QUINT)
		var rand := randf_range(0.5, 1.0)
		var color_target := Color()
		color_target = Color(1, 1, 1) if randf() < 0.5 else actor.modulate
		color_target = color_target.lerp(color, rand)
		tw.tween_property(actor, "modulate", color_target , rand)


func _to_string() -> String:
	return ("StatusEffectType(" +
		"s_id=" + s_id +
		", name=" + name +
		", turn_payload=" + str(turn_payload) +
		")"
	)
