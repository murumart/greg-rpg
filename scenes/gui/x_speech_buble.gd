extends Node2D

const CON_MIN_SIZE := Vector2(55, 40)

@onready var pointer_line: Line2D = $PointerLine
@onready var container: PanelContainer = $Container

var _pp: Vector2:
	set(to): pointer_line.points[1] = to
	get: return pointer_line.points[1]
var _sp: Vector2:
	set(to): pointer_line.points[0] = to
	get: return pointer_line.points[0]


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().process_frame
	global_position = Vector2.ZERO
	get_parent().remove_child(self)
	SOL.add_ui_child(self)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"mouse_left"):
		var adj := to_local(get_global_mouse_position())
		print(self.name + " ADJ MOUSE: ", adj)
		#bang(adj - SOL.SCREEN_CENTER)
		repos(adj)
		print(self.name + " YEAH.....\n")


func repos(guipos: Vector2) -> void:
	const pad := 7.0
	const delay := 0.2
	const edgepad := 3.0
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
	tw.tween_property(self, ^"_pp", guipos, delay)
	var taillen := randf_range(26, 40)
	var sp := -guipos.direction_to(SOL.SCREEN_CENTER) * taillen + SOL.SCREEN_CENTER
	tw.parallel().tween_property(self, ^"_sp", sp, delay)

	var cp := sp
	var cs := Vector2(80, 40)
	if (sp.x < SOL.SCREEN_CENTER.x and sp.x < guipos.x) or guipos.x > sp.x:
		cp.x -= cs.x
		cp.x += pad
	else:
		cp.x -= pad
	if sp.y < SOL.SCREEN_CENTER.y:
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
	tw.parallel().tween_property(container, ^"size", cs, delay)
	tw.parallel().tween_property(container, ^"position", cp, delay)




func bang(guipos: Vector2) -> void:
	SOL.vfx("bangspark", guipos)
