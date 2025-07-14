@tool
class_name TreeDecor extends Node2D

# trees in the overworld

@export_enum("kuusk", "mänd", "tooming", "kadak", "toone", "paju") var type: int = 0: set = set_type
const TYPES_SIZE := 4

@onready var sprite := $Sprite
@onready var face: Sprite2D = $Sprite/Face
@onready var behind_area: Area2D = $BehindArea
@onready var visibility_notif: VisibleOnScreenNotifier2D = $VisibilityNotif

@export var randomise_trees := false: set = activate_randomise_trees
@export var face_visible := false:
	set(to):
		$Sprite/Face.visible = to
		face_visible = to


func _ready() -> void:
	if not Engine.is_editor_hint():
		screen(false)
		visibility_notif.screen_entered.connect(screen.bind(true))
		visibility_notif.screen_exited.connect(screen.bind(false))


func screen(on: bool) -> void:
	behind_area.monitoring = on
	sprite.visible = on


func set_type(to: int) -> void:
	sprite = $Sprite
	sprite.region_rect.position.x = 16 + to * 48
	type = to


func activate_randomise_trees(_to: bool) -> void:
	# randomise all trees in the current scene
	if not Engine.is_editor_hint(): return
	if not is_visible_in_tree(): return
	if not is_inside_tree(): return
	for i in get_tree().get_nodes_in_group("trees"):
		i.set_type(randi() % TYPES_SIZE)
		i.scale.x = signf(randf_range(-1, 1)) * 1
