extends OverworldCharacter

@onready var visible_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@export_group("Interaction")
@export var escape_offset := Vector2(0, 0)

var discovered := false

@onready var r4si := remap(
	hash(hash(hash(name + LTS.get_current_scene().name + str(global_position)))),
	0, 9999999999, 0.0, 1.0)


func _ready() -> void:
	var nr := DAT.get_data("nr", 0.0) as float
	if not is_equal_approx(
			snapped(nr, 0.1),
			snapped(r4si, 0.1)
		):
			queue_free()
			return
	if DAT.get_data(get_save_key("seen"), false):
		queue_free()
		return
	super()
	visible_notifier.screen_entered.connect(_on_discovered)


func _on_discovered() -> void:
	if discovered:
		return
	discovered = true
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.BLACK, 1.0).from(Color.WHITE)
	DAT.set_data(get_save_key("seen"), true)
	set_collision_mask_value(1, false)
	move_to(position + escape_offset)
	target_reached.connect(queue_free)


func get_save_key(key: String) -> StringName:
	return (&"business_" + name.to_snake_case() + &"_in_" +
		LTS.get_current_scene().name.to_snake_case() + &"_" + key)
