extends Node2D

const DAY := 86400 # 24 hrs * 60 mins * 60 secs
const ITEMS := [
	&"muesli", # sunday
	&"mueslibar", # monday
	&"milkshake", # tuesday
	&"funny_fungus", # wednesday
	&"free_hugs_coupon", # thursday
	&"meat_cooked", # friday
	&"mirror", # saturday
]
const KEY_DAILY_ITEM_COLLECTED := &"daily_item_collected"

@onready var trash_bin: TrashBin = $TrashBin
@onready var interaction_area: InteractionArea = $Sprite2D/InteractionArea
@onready var ui: Control = $Ui
@onready var refill_sound: AudioStreamPlayer = $RefillSound
@onready var refill_timer: Timer = $RefillTimer
@onready var sparkles: GPUParticles2D = $Sparkles


func _ready() -> void:
	trash_bin.failed_to_open.connect(_cant_collect)
	trash_bin.opened.connect(_collect_trash)
	var weekday: Time.Weekday = Time.get_date_dict_from_system().weekday
	trash_bin.item = ITEMS[weekday]
	remove_child(ui)
	SOL.add_ui_child(ui)
	ui.hide()
	interaction_area.on_interact.connect(_poster_viewed)

	_check_refill()
	refill_timer.timeout.connect(func(): if not trash_bin.full: _check_refill())


func _unhandled_key_input(event: InputEvent) -> void:
	event = event as InputEventKey
	if not is_instance_valid(event):
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("escape"):
		if "poster" in DAT.player_capturers:
			DAT.free_player("poster")
			ui.hide()


func _collect_trash() -> void:
	var time := int(Time.get_unix_time_from_system())
	DAT.set_data(KEY_DAILY_ITEM_COLLECTED, time)


func _cant_collect() -> void:
	if _check_refill():
		return
	var string := Time.get_time_string_from_unix_time(get_refill_time_left())
	SOL.dialogue_box.dial_concat("daily_trash_wait", 0, [string])
	SOL.dialogue("daily_trash_wait")


func get_refill_time_left() -> int:
	var time := int(Time.get_unix_time_from_system())
	var collected: int = DAT.get_data(KEY_DAILY_ITEM_COLLECTED, 0)
	var time_left := (int(
			collected + DAY - time))
	return time_left


func _check_refill() -> bool:
	if get_refill_time_left() <= 0:
		refill_trash()
		sparkles.emitting = true
		return true
	sparkles.emitting = false
	return false


func _poster_viewed() -> void:
	SND.play_sound(preload("res://sounds/paper/paper1.ogg"))
	ui.show()
	DAT.capture_player("poster")


func refill_trash() -> void:
	trash_bin.full = true
	refill_sound.play()
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(trash_bin, "scale", Vector2(1.2, 0.8), 0.1)
	tw.tween_property(trash_bin, "scale", Vector2(0.8, 1.2), 0.1)
	tw.tween_property(trash_bin, "scale", Vector2(1, 1), 0.2)
	SOL.vfx_damage_number(trash_bin.global_position - Vector2(16, 15), "!",
			Color.WHITE, 1.0, {"gravity": 0})
