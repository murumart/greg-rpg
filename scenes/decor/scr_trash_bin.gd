@tool
extends Node2D

# trash bins in overworld that contain loot

@export var full := true : set = set_full
@export var replenish_minutes := 25:
	set(to):
		replenish_minutes = to
		replenish_seconds = int(replenish_minutes * 60)
@export var replenish_seconds := 1500
@export var item := &""
@export var silver := 0


func _ready() -> void:
	if Engine.is_editor_hint(): return
	check_full_time_passed()


func _on_interaction_area_on_interact() -> void:
	if full:
		DAT.set_data(save_key("emptied_second"), DAT.seconds)
		full = false
		SND.play_sound(preload("res://sounds/snd_trashbin.ogg"))
		if item:
			DAT.grant_item(item)
		if silver:
			DAT.grant_silver(silver)
		if (item.length() < 1) and (not bool(silver)):
			SOL.dialogue("nothing")
		DAT.incri("trashcans_emptied", 1)


func set_full(to: bool) -> void:
	full = to
	var sprite := $Sprite2D
	sprite.region_rect.position.x = int(not to) * 16


func save_key(key: String) -> String:
	return "trash_bin_%s_in_%s_%s" % [name, DAT.get_current_scene().name, key]


# save the time when the bin was last emptied, then compare with current time
func check_full_time_passed() -> void:
	var emptied_second : int = DAT.get_data(save_key("emptied_second"), -3999999999)
	if DAT.seconds - emptied_second > replenish_seconds:
		full = true
	else:
		full = false


func _on_timer_timeout() -> void:
	check_full_time_passed()
