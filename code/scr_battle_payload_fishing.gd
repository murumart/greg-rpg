class_name BattlePayloadFishing extends BattlePayload

@export var world_hitbox_size_multiplier := 1.0
@export var horizontal_movement_speed_multiplier := 1.0
@export var vertical_movement_speed_multiplier := 1.0

@export var fish_hitbox_size_multiplier := 1.0
@export var combo_time_multiplier := 1.0
@export var point_multiplier := 1.0

@export var item_id: StringName


func get_effect_description() -> String:
	var text := super()
	text += "[color=#4455ff]fishing info:\n"
	if world_hitbox_size_multiplier != 1.0:
		text += ("hitbox sze mlt: "
		+ str(snappedf(world_hitbox_size_multiplier, 0.01)) + "\n")
	if horizontal_movement_speed_multiplier != 1.0:
		text += ("horiz mv spd mlt: "
		+ str(snappedf(horizontal_movement_speed_multiplier, 0.01)) + "\n")
	if vertical_movement_speed_multiplier != 1.0:
		text += ("vert move spd mlt: "
		+ str(snappedf(vertical_movement_speed_multiplier, 0.01)) + "\n")
	if fish_hitbox_size_multiplier != 1.0:
		text += ("fish catch sze mlt: "
		+ str(snappedf(fish_hitbox_size_multiplier, 0.01)) + "\n")
	if combo_time_multiplier != 1.0:
		text += ("combo time mlt: "
		+ str(snappedf(combo_time_multiplier, 0.01)) + "\n")
	if point_multiplier != 1.0:
		text += ("point mult: "
		+ str(snappedf(point_multiplier, 0.01)) + "\n")
	return text


func set_fishing_data() -> void:
	DAT.set_data("fishing_hook_data", item_id)
	SND.play_sound(preload("res://sounds/equip.ogg"))
