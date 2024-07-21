extends OverworldCharacter

signal finished_talking
signal exchange_completed(exchange: Exchange)

@export var trades: Array[Exchange] = []
@onready var trades_dict := {}


func _ready() -> void:
	load_trades()
	super._ready()
	default_lines.clear()
	default_lines.append("kid_hi")


func load_trades() -> void:
	trades_dict.clear()
	for i in trades:
		trades_dict[i.title] = i


func interacted() -> void:
	SOL.dialogue_box.adjust(default_lines[0], 1, "choices",
			Math.reaap(trades_dict.keys(), "nvm"))
	super.interacted()
	SOL.dialogue_closed.connect(func():
		if SOL.dialogue_choice == "nvm" or SOL.dialogue_choice == "no":
			self.finished_talking.emit()
			return
		var key: StringName = SOL.dialogue_choice
		trades_dict[key].state(Exchange.Statements.CRITERIA)
		trades_dict[key].state(Exchange.Statements.RETURNS)
		SOL.dialogue("kid_trade_confirmation")
		SOL.dialogue_closed.connect(func():
			if SOL.dialogue_choice == "no":
				self.finished_talking.emit()
				return
			var success := trades_dict[key].exchange(
					ResMan.get_character("greg").inventory) as bool
			if success:
				print("trade success")
				SOL.dialogue("kid_trade_success")
				DAT.incri("kid_reputation", 1)
				exchange_completed.emit(trades_dict[key])
			else:
				SOL.dialogue("kid_trade_fail")
			SOL.dialogue_closed.connect(func():
				print("emitting finished talking")
				self.finished_talking.emit()
			, CONNECT_ONE_SHOT)
		,CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)
