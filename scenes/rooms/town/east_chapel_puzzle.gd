extends Node

@onready var fence: TileMapLayer = $"../Tiles/Fence"
@onready var light_receiver_block := $"../Puzzle/LightReceiverBlock"


func _ready() -> void:
	funcon()
	light_receiver_block.activated.connect(func() -> void:
		if not DAT.get_data("chape_puzzle_complete", false):
			DAT.set_data("chape_puzzle_complete", true)
			var t := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			t.tween_property(fence, ^"modulate:a", 0.0, 1.0)
			t.tween_callback(fence.queue_free)
	)


func funcon() -> void:
	if DAT.get_data("chape_puzzle_complete", false):
		fence.queue_free()
