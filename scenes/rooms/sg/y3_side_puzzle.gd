extends Node2D

@onready var itemblocker: StaticBody2D = $Itemblocker
@onready var light_target_block := $LightTargetBlock
@onready var halo_item: PickableItem = $"../HaloItem"

var done: bool:
	set(to): DAT.set_data("y3sidepuzzle_done", to)
	get: return DAT.get_data("y3sidepuzzle_done", false)


func _ready() -> void:
	if done:
		itemblocker.queue_free()
		halo_item.show()
		return
	light_target_block.activated.connect(func() -> void:
		done = true
	)
