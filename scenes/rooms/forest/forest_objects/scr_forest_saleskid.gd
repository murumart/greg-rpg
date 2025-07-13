extends Node2D

static var loaded_exchanges := {}
var _traded := false

@onready var kid := $KidOverworld


static func _static_init() -> void:
	for s in ResMan._get_dir_contents("res://resources/exchanges/forest/"):
		loaded_exchanges[s] = load(
				"res://resources/exchanges/forest/" + s + ".tres") as Exchange


func _ready() -> void:
	add_to_group("forest_curiosities")
	if DAT.get_data("kid_never_meet_again", false):
		queue_free()
		return
	const KidType := preload("res://scenes/characters/overworld/scr_kid_overworld.gd")
	_pick_random_exchanges()
	kid = kid as KidType
	kid.load_trades()
	kid.default_lines[0] = "kid_hi_forest"
	if _creeptpasta():
		kid.default_lines[0] = "kid_hi_forest_secredt_fucked_up_version"
	kid.exchange_completed.connect(func(_a):
		_traded = true
	, CONNECT_ONE_SHOT)
	kid.finished_talking.connect(func():
		if not _traded:
			if _creeptpasta():
				DAT.set_data("kid_never_meet_again", true)
			return
		if not is_instance_valid(get_parent()):
			queue_free()
			return
		for x in 5:
			SOL.vfx("bird_flight", global_position,
					{parent = get_parent(), speed = randf_range(100.0, 120.0)})
		remove_from_group("forest_curiosities")
		queue_free()
	)


func _pick_random_exchanges() -> void:
	kid.trades.clear()
	for i in 3:
		var exchange: Exchange = loaded_exchanges[loaded_exchanges.keys().pick_random()]
		if exchange in kid.trades:
			continue
		kid.trades.append(exchange)


func _creeptpasta() -> bool:
	return (Math.inrange(DAT.get_data("nr", 0), 0.55, 0.56)
			and randf() < 0.01
			and ResMan.get_character("greg").level > 85
			and DAT.get_data("forest_depth", 0) > 11)
