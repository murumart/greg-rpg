extends TileMapLayer

@export var get_on_areas: Array[Area2D]
@export var get_off_areas: Array[Area2D]
@export var on_path_collision: TileMapLayer
@export var off_path_collision: TileMapLayer

var on_path: bool:
	set(to): DAT.set_data("sg_b_3_on_path", to)
	get: return DAT.get_data("sg_b_3_on_path", false)


func _ready() -> void:
	print("3d room: checking data")
	if on_path: _get_on()
	else: _get_off()

	print("3d room: connecting..")
	for a in get_on_areas:
		a.body_entered.connect(_get_on.unbind(1))
	for a in get_off_areas:
		a.body_entered.connect(_get_off.unbind(1))


func _get_on() -> void:
	print("3d room: onto path")
	z_index = 0
	off_path_collision.enabled = false
	on_path_collision.enabled = true
	on_path = true


func _get_off() -> void:
	print("3d room: off path")
	z_index = 1
	off_path_collision.enabled = true
	on_path_collision.enabled = false
	on_path = false
