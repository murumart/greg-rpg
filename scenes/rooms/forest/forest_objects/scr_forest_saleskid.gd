extends Node2D

static var loaded_exchanges := {}
var _traded := false

@onready var kid := $KidOverworld


static func _static_init() -> void:
	for s in ResMan._get_dir_contents("res://resources/exchanges/forest/"):
		loaded_exchanges[s] = load(
				"res://resources/exchanges/forest/" + s + ".tres") as Exchange


func _ready() -> void:
	const KidType := preload("res://scenes/characters/overworld/scr_kid_overworld.gd")
	_pick_random_exchanges()
	kid = kid as KidType
	kid.load_trades()
	kid.default_lines[0] = "kid_hi_forest"
	kid.exchange_completed.connect(func(_a):
		_traded = true
	, CONNECT_ONE_SHOT)
	kid.finished_talking.connect(func():
		print("kid finished talking")
		if not _traded:
			return
		print("we have traded")
		if not is_instance_valid(get_parent()):
			queue_free()
			return
		for x in 5:
			SOL.vfx("bird_flight", global_position,
					{parent = get_parent(), speed = randf_range(100.0, 120.0)})
		queue_free()
	)


func _pick_random_exchanges() -> void:
	kid.trades.clear()
	for i in 3:
		var exchange: Exchange = loaded_exchanges[loaded_exchanges.keys().pick_random()]
		if exchange in kid.trades:
			continue
		kid.trades.append(exchange)
