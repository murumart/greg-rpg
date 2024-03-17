extends OverworldCharacter

@export var trades: Array[Exchange] = []
@onready var trades_dict := (func():
	var dict := {}
	for i in trades:
		dict[i.title] = i
	return dict).call() as Dictionary


func _ready() -> void:
	super._ready()


func interacted() -> void:
	default_lines.clear()
	default_lines.append("kid_hi")
	SOL.dialogue_box.adjust("kid_hi", 1, "choices",
	Math.reaap(trades_dict.keys(), "nvm"))
	super.interacted()
	SOL.dialogue_closed.connect(func():
		if SOL.dialogue_choice == "nvm" or SOL.dialogue_choice == "no": return
		var key := SOL.dialogue_choice
		trades_dict[key].state(Exchange.Statements.CRITERIA)
		trades_dict[key].state(Exchange.Statements.RETURNS)
		SOL.dialogue("kid_trade_confirmation")
		SOL.dialogue_closed.connect(func():
			if SOL.dialogue_choice == "no": return
			var success := trades_dict[key].exchange(
			ResMan.get_character("greg").inventory) as bool
			if success:
				SOL.dialogue("kid_trade_success")
				DAT.incri("kid_reputation", 1)
			else:
				SOL.dialogue("kid_trade_fail")
		,CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)
