extends Control

signal spirit_gotten(spirit_id: StringName)
signal not_enough_sp_spirit_gotten
signal invalid_spirit_gotten
signal timed_out

const SPIRIT_SPEAK_TIMER_WAIT := 2.0
const LS := preload("res://resources/ls_logo_label.tres")

const SND_FAIL_2 = preload("uid://buqp3rch2u0bm")
const SND_FAIL = preload("uid://dv66bhp5avl0d")

const LETTER_SOUNDS: Array[AudioStream] = [preload("uid://bf2qsvwtksbqn"), preload("uid://omilrexxdeq1"), preload("uid://crfyebhqech6w"), preload("uid://p2llnq72nogr")]

const SND_FOUND = preload("uid://hp3jx7r8qcmy")

const WAIT_CORRECT := 1.5
const WAIT_INVALID := 0.5

@export var battle: Battle

const DEFAULT_INTENSITY := 3.0
@export var intensity := 4.0
const DEFAULT_SPEED := 2.0
@export var speed := 2.0
@export var idiff := 0.0002
const DEFAULT_RMUL := 0.91
@export var rmul: float:
	get: return get_indexed("letter_container:material:shader_parameter/rmul")
	set(to): set_indexed("letter_container:material:shader_parameter/rmul", to)
const DEFAULT_GMUL := 0.975
@export var gmul: float:
	get: return get_indexed("letter_container:material:shader_parameter/gmul")
	set(to): set_indexed("letter_container:material:shader_parameter/gmul", to)

@onready var spirit_speak_timer := %SpiritSpeakTimer
@onready var spirit_speak_timer_progress := %SpiritSpeakTimerProgress
@onready var letter_container: HBoxContainer = $LetterContainer
@onready var overlay: Sprite2D = $Overlay
@onready var cool_text: RichTextLabel = $Overlay/CoolText

var _loaded_spirits: Dictionary[String, StringName] = {}

var _active := false
var _text := ""


func _ready() -> void:
	spirit_speak_timer.timeout.connect(_on_spirit_speak_timer_timeout)


var _d: float

func _process(delta: float) -> void:
	if not visible:
		return
	spirit_speak_timer_progress.value = remap(
		spirit_speak_timer.time_left, 0.0,
		SPIRIT_SPEAK_TIMER_WAIT, 0.0, 100.0)
	for i in letter_container.get_child_count():
		var c: Control = letter_container.get_child(i)
		c.offset_transform_position.x = sin(_d * speed + i * idiff) * intensity * (1.0 - (7 - i) * 0.2)
		c.offset_transform_position.y = cos(_d * speed + i * idiff) * intensity
		c.offset_transform_position.y = sin(c.position.x + _d * speed) * intensity
	_d += delta


func _unhandled_key_input(ev: InputEvent) -> void:
	if not _active: return
	var e := ev as InputEventKey
	if not e.pressed: return
	if e.keycode == KEY_ENTER or e.keycode == KEY_KP_ENTER:
		_on_spirit_name_submitted(_text)
		return
	if e.keycode == KEY_BACKSPACE:
		if not _text.is_empty():
			_remove_letter()
		return
	if e.get_modifiers_mask() & KEY_MODIFIER_MASK != 0: return
	if e.keycode == KEY_SPACE:
		_add_letter(" ")
		return
	var l := OS.get_keycode_string(e.keycode).to_lower()
	if l.length() != 1:
		return
	_add_letter(l)


func _add_letter(letter: String) -> void:
	assert(letter.length() == 1, "ltter length should be 1")
	_text += letter
	letter_container.add_child(_letter(letter))
	letter_container.offset_transform_scale = Vector2.ONE
	if _text.length() >= 12:
		letter_container.offset_transform_scale = Vector2.ONE * 0.5
	_on_spirit_name_changed(_text)


func _remove_letter() -> void:
	_text = _text.substr(0, _text.length() - 1)
	letter_container.remove_child(letter_container.get_child(-1))
	letter_container.offset_transform_scale = Vector2.ONE
	if _text.length() >= 12:
		letter_container.offset_transform_scale = Vector2.ONE * 0.5
	_on_spirit_name_changed(_text)


func open() -> void:
	letter_container.modulate.a = 1.0
	cool_text.modulate.a = 0.0
	_clear_letters()
	spirit_speak_timer_progress.modulate.a = 1.0
	_text = ""
	spirit_speak_timer.paused = false
	spirit_speak_timer.start(SPIRIT_SPEAK_TIMER_WAIT)
	for i in battle.current_guy.character.spirits:
		var spirit: Spirit = ResMan.get_spirit(i)
		_loaded_spirits[spirit.name] = i
	show()
	_active = true
	intensity = DEFAULT_INTENSITY
	speed = DEFAULT_SPEED
	rmul = DEFAULT_RMUL
	gmul = DEFAULT_GMUL
	_set_music_volume(0.1)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(overlay, "scale:y", 1.0, 0.1).from(0.0)


func close() -> void:
	_active = false
	if visible:
		_reset_music_volume()
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(overlay, "scale:y", 0.0, 0.1).from(1.0)
		tw.parallel().tween_property(letter_container, ^"modulate:a", 0.0, 0.1)
		tw.parallel().tween_property(cool_text, ^"modulate:a", 0.0, 0.2)
		tw.tween_callback(hide)


# you didn't type the spirit name fast enough
func _on_spirit_speak_timer_timeout() -> void:
	_active = false
	rmul = 0.0
	SND.play_sound(SND_FAIL_2, {pitch_scale = 1.0})
	await Math.timer(WAIT_INVALID)
	timed_out.emit()


func _on_spirit_name_changed(to: String) -> void:
	to = to.to_lower() # no uppercase
	SND.play_sound(LETTER_SOUNDS.pick_random())
	if to in _loaded_spirits.keys():
		_on_spirit_name_submitted(to)
		return


func _on_spirit_name_submitted(submission: String) -> void:
	_active = false
	spirit_speak_timer.paused = true
	var ltw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	ltw.tween_property(spirit_speak_timer_progress, ^"modulate:a", 0.0, 0.5)
	if submission in _loaded_spirits.keys():
		var spirit_id = _loaded_spirits[submission]
		var spirit := ResMan.get_spirit(spirit_id)
		if spirit.cost <= battle.current_guy.character.magic:
			var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
			tw.tween_property(self, ^"intensity", DEFAULT_INTENSITY * 4.0, 1.5)
			cool_text.text = spirit.name.replace(" ", "").repeat(400)
			tw.parallel().tween_property(cool_text, ^"modulate:a", 0.7, 0.7).set_delay(0.4)
			_pinch()
			SND.play_sound(SND_FOUND)
			await Math.timer(WAIT_CORRECT)
			spirit_gotten.emit(spirit_id)
			return
		else:
			SND.play_sound(SND_FAIL)
			speed = 0.0
			rmul = 0.0
			gmul = 0.1
			await Math.timer(WAIT_INVALID)
			gmul = 1.0
			_set_text("not enough sp")
			letter_container.offset_transform_scale = Vector2.ONE * 0.5
			intensity = DEFAULT_INTENSITY * 0.25
			SND.play_sound(SND_FAIL_2)
			await Math.timer(WAIT_INVALID * 2.0)
			not_enough_sp_spirit_gotten.emit()
	else:
		if _text == "":
			_set_text("no name given")
		elif battle.current_guy.character.unused_spirits.any(func(s: StringName) -> bool: return ResMan.get_spirit(s).name == _text):
			_set_text("spirit not equipped")
		elif ResMan.spirits.values().any(func(s: Spirit) -> bool: return s.name == _text):
			_set_text("spirit not known")
		else:
			_set_text(["what...", "no...?", "nope", "no such spirit", "no can do"].pick_random())
		letter_container.offset_transform_scale = Vector2.ONE * 0.5
		intensity = DEFAULT_INTENSITY * 0.25
		SND.play_sound(SND_FAIL_2)
		await Math.timer(WAIT_INVALID * 2.0)
		invalid_spirit_gotten.emit()


func _letter(lt: String) -> Label:
	assert(lt.length() == 1, "letter should be one letter long, got `%s` isntead" % lt)
	var l := Label.new()
	l.label_settings = LS
	l.text = lt
	l.offset_transform_enabled = true
	l.use_parent_material = true
	return l


func _set_music_volume(mul: float) -> void:
	var vol := AudioServer.get_bus_volume_linear(OPT.AB_MUSIC)
	var end := vol * mul
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(_set_music_bus_volume, vol, end, 0.5)


func _reset_music_volume() -> void:
	var vol := AudioServer.get_bus_volume_linear(OPT.AB_MUSIC)
	var end: float = OPT.get_opt("music_volume")
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(_set_music_bus_volume, vol, end, 0.5)


func _set_music_bus_volume(vol: float) -> void:
	AudioServer.set_bus_volume_linear(OPT.AB_MUSIC, vol)


func _pinch(delay: float = 0.05) -> void:
	var tw := create_tween().set_parallel()
	for i in letter_container.get_child_count():
		var child: Label = letter_container.get_child(i)
		tw.tween_property(child, ^"offset_transform_scale:x", 0.0, 1.0).set_delay(delay * i)


func _clear_letters() -> void:
	letter_container.get_children().map(func(n: Node) -> void: n.queue_free())


func _set_text(to: String) -> void:
	_text = to
	_clear_letters()
	for i in to:
		letter_container.add_child(_letter(i))
