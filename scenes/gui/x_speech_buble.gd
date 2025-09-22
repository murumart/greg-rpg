extends Node2D

const CON_MIN_SIZE := Vector2(55, 40)

signal _continue
signal _cancel

@onready var pointer_line: Line2D = $PointerLine
@onready var container: PanelContainer = $Container
@onready var textbox: TextBox = $Container/MarginContainer/Textbox


@warning_ignore("unused_private_class_variable") var _pp: Vector2:
	set(to): pointer_line.points[1] = to
	get: return pointer_line.points[1]

@warning_ignore("unused_private_class_variable") var _sp: Vector2:
	set(to): pointer_line.points[0] = to
	get: return pointer_line.points[0]


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().process_frame
	global_position = Vector2.ZERO
	get_parent().remove_child(self)
	SOL.add_ui_child(self)
	hide()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept"):
		_continue.emit()
	if event.is_action_pressed(&"cancel"):
		_cancel.emit()


func _process(_delta: float) -> void:
	if Input.is_action_pressed(&"mouse_left"):
		var adj := to_local(get_global_mouse_position())
		print(self.name + " ADJ MOUSE: ", adj)
		#bang(adj - SOL.SCREEN_CENTER)
		repos(adj, false, false)
		print(self.name + " YEAH.....\n")


func shun() -> void:
	const up := Vector2(SOL.SCREEN_CENTER.x, 0)
	_tw_arrow(up, up, 0.1)
	await _tw_box(Vector2.ZERO, up, 0.2)
	hide()


func exhibit() -> void:
	show()
	container.size = Vector2.ZERO
	_pp = SOL.SCREEN_CENTER
	_sp = SOL.SCREEN_CENTER


func repos(guipos: Vector2, inverse := false, rand_dist := true) -> void:
	const pad := 12.0
	const delay := 0.2
	const edgepad := 3.0
	var taillen := randf_range(12, 32) if rand_dist else 22.0
	var sp := (-1 if inverse else 1) * guipos.direction_to(
		SOL.SCREEN_CENTER) * taillen + SOL.SCREEN_CENTER

	var cp := sp
	var cs := Vector2(80, 40)
	#cp.x -= lerpf(0, cs.x, sp.x / SOL.SCREEN_SIZE.x)
	if (sp.x < SOL.SCREEN_CENTER.x and sp.x < guipos.x) or guipos.x > sp.x:
		cp.x -= cs.x
		cp.x += pad
	else:
		cp.x -= pad
	#cp.y -= lerpf(0, cs.y, sp.y / SOL.SCREEN_SIZE.y)
	if (sp.y < SOL.SCREEN_CENTER.y and sp.y < guipos.y) or guipos.y > sp.y:
		cp.y -= cs.y
		cp.y += pad
	else:
		cp.y -= pad

	if cp.x < edgepad:
		cs.x -= edgepad - cp.x
		if cs.x < CON_MIN_SIZE.x:
			cp.x -= CON_MIN_SIZE.x - cs.x
			cs.x = CON_MIN_SIZE.x
		cp.x = edgepad
	if cp.x + cs.x > SOL.SCREEN_SIZE.x - edgepad:
		cs.x = SOL.SCREEN_SIZE.x - edgepad - cp.x
		if cs.x < CON_MIN_SIZE.x:
			cp.x -= CON_MIN_SIZE.x - cs.x
			cs.x = CON_MIN_SIZE.x

	if cp.y < edgepad:
		cs.y -= edgepad - cp.y
		if cs.y < CON_MIN_SIZE.y:
			cp.y -= CON_MIN_SIZE.y - cs.y
			cs.y = CON_MIN_SIZE.y
		cp.y = edgepad
	if cp.y + cs.y > SOL.SCREEN_SIZE.y - edgepad:
		cs.y = SOL.SCREEN_SIZE.y - edgepad - cp.y
		if cs.y < CON_MIN_SIZE.y:
			cp.y -= CON_MIN_SIZE.y - cs.y
			cs.y = CON_MIN_SIZE.y

	#container.position = cp
	#container.size = cs
	_tw_arrow(guipos, sp, delay)
	await _tw_box(cs, cp, delay)


func _tw_arrow(pp: Vector2, sp: Vector2, delay: float) -> void:
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, ^"_pp", pp, delay)
	tw.parallel().tween_property(self, ^"_sp", sp, delay)


func _tw_box(cs: Vector2, cp: Vector2, delay: float) -> void:
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(container, ^"size", cs, delay)
	tw.parallel().tween_property(container, ^"position", cp, delay)
	await tw.finished


func speak(dlg: Dialogue) -> void:
	show()
	DAT.capture_player("dialogue")
	SOL.dialogue_open = true

	for line in dlg.lines:
		textbox.text = line.text
		textbox.speak_text()
		var skipf := func() -> void:
			textbox.skip_to_end()
			textbox.speak_finished.emit()
			#print("le sip")
		if OPT.get_opt("z_skips_dialogue") > 0: _continue.connect(skipf, CONNECT_ONE_SHOT)
		_cancel.connect(skipf, CONNECT_ONE_SHOT)
		#print("awaitn finsh speak")
		await textbox.speak_finished
		if _continue.is_connected(skipf): _continue.disconnect(skipf)
		if _cancel.is_connected(skipf): _cancel.disconnect(skipf)
		#print("awaitng continue")
		await _continue

	await shun()
	DAT.free_player.call_deferred("dialogue")
	SOL.set_deferred("dialogue_open", false)



func bang(guipos: Vector2) -> void:
	SOL.vfx("bangspark", guipos)
