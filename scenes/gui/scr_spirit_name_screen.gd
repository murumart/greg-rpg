extends Control

signal spirit_gotten(spirit_id: StringName)
signal not_enough_sp_spirit_gotten
signal invalid_spirit_gotten
signal timed_out

const SPIRIT_SPEAK_TIMER_WAIT := 2.0

const WAIT_CORRECT := 1.5
const WAIT_INVALID := 0.5

@export var battle: Battle

@onready var spirit_name := %SpiritName
@onready var spirit_speak_timer := %SpiritSpeakTimer
@onready var spirit_speak_timer_progress := %SpiritSpeakTimerProgress

var loaded_spirits: Dictionary[String, StringName] = {}


func _ready() -> void:
	spirit_name.text_changed.connect(_on_spirit_name_changed)
	spirit_name.text_submitted.connect(_on_spirit_name_submitted)
	spirit_speak_timer.timeout.connect(_on_spirit_speak_timer_timeout)


func _process(_delta: float) -> void:
	if not visible:
		return
	spirit_speak_timer_progress.value = remap(
		spirit_speak_timer.time_left, 0.0,
		SPIRIT_SPEAK_TIMER_WAIT, 0.0, 100.0)


func open() -> void:
	spirit_name.add_theme_font_size_override("font_size", 16)
	spirit_name.text = ""
	spirit_name.editable = true
	spirit_speak_timer.paused = false
	spirit_speak_timer.start(SPIRIT_SPEAK_TIMER_WAIT)
	for i in battle.current_guy.character.spirits:
		var spirit: Spirit = ResMan.get_spirit(i)
		loaded_spirits[spirit.name] = i
	show()
	while not spirit_name.has_focus():
		spirit_name.grab_focus()


func close() -> void:
	hide()


# you didn't type the spirit name fast enough
func _on_spirit_speak_timer_timeout() -> void:
	SND.play_sound(
			preload("res://sounds/error.ogg"),
			{pitch_scale = 0.7, bus = "ECHO"})
	spirit_name.text = "moment passed"
	spirit_name.editable = false
	await Math.timer(WAIT_INVALID)
	timed_out.emit()


func _on_spirit_name_changed(to: String) -> void:
	to = to.to_lower() # no uppercase
	spirit_name.text = to
	spirit_name.caret_column = to.length()
	spirit_name.add_theme_font_size_override("font_size", 16)
	if to.length() > 12:
		spirit_name.add_theme_font_size_override("font_size", 8)
	SND.play_sound(
			preload("res://sounds/gui.ogg"),
			{"bus": "ECHO", "pitch_scale":
				[1.0, 1.0, 1.18921, 1.7818].pick_random()})
	if to in loaded_spirits.keys():
		_on_spirit_name_submitted(to)
		return
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(spirit_name, "modulate", Color(0.8, 0.8, 8.0, 2.0), 0.1)
	tw.tween_property(spirit_name, "modulate", Color(1, 1, 1, 1), 0.3)


func _on_spirit_name_submitted(submission: String) -> void:
	spirit_name.editable = false
	get_viewport().gui_release_focus()
	spirit_speak_timer.paused = true
	if submission in loaded_spirits.keys():
		var spirit_id = loaded_spirits[submission]
		var spirit := ResMan.get_spirit(spirit_id)
		if spirit.cost <= battle.current_guy.character.magic:
			SND.play_sound(preload("res://sounds/spirit/spirit_name_found.ogg"))
			var tw := create_tween().set_trans(Tween.TRANS_QUART)
			tw.tween_property(spirit_name, "modulate", Color(2, 2, 2, 10), 1.5)
			await Math.timer(WAIT_CORRECT)
			spirit_gotten.emit(spirit_id)
			return
		else:
			spirit_name.text = "not enough sp!"
			await Math.timer(WAIT_INVALID)
			not_enough_sp_spirit_gotten.emit()
	else:
		SND.play_sound(preload("res://sounds/error.ogg"), {bus = "ECHO"})
		await Math.timer(WAIT_INVALID)
		invalid_spirit_gotten.emit()
