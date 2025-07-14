extends "res://scenes/rooms/forest/forest_objects/scr_puzzle_column.gd"

@onready var animation_player: AnimationPlayer = $AnimationPlayer

static var loaded_exchanges: Dictionary[StringName, Exchange]
static func _static_init() -> void:
	for s in ResMan._get_dir_contents("res://resources/exchanges/forest/yellow/"):
		loaded_exchanges[s] = load(
				"res://resources/exchanges/forest/yellow/" + s + ".tres") as Exchange

var trades: Array[StringName]


func _ready() -> void:
	super()
	if active:
		animation_player.play(&"active")
		remove_from_group(&"forest_curiosities")
		return
	_pick_random_exchanges()


func _interacted() -> void:
	if active:
		SOL.dialogue("insp_yellow_column_active")
		return
	var dlg := DialogueBuilder.new()
	if not DAT.get_data("yellow_column_lore", false):
		DAT.set_data("yellow_column_lore", true)
		dlg.add_line(dlg.ml("the people of this world deal only in silver."))
		dlg.add_line(dlg.ml("but, there was a time and space where gold ruled everything."))
		dlg.add_line(dlg.ml("we remember."))
		dlg.add_line(dlg.ml("and look at you, asking to grow..."))
		dlg.add_line(dlg.ml("gold neither rots nor rusts."))
		dlg.add_line(dlg.ml("how can you grow around something that tarnishes?"))
		dlg.add_line(dlg.ml("then, if you want to rule the world, together, once more..."))
		dlg.add_line(dlg.ml("please, bring me some gold."))
		await dlg.speak_choice()
	dlg.reset().add_line(dlg.ml("in exchange for gold, i can bless a breath of your journey."))
	var inv := ResMan.get_character("greg").inventory
	if not &"gold" in inv:
		dlg.add_line(dlg.ml("however, you don't have any at this time."))
		await dlg.speak_choice()
		return
	await dlg.speak_choice()
	while true:
		var aval_choices: Array[StringName] = [&"bye"]
		for t in trades:
			print(t)
			aval_choices.push_front(StringName(loaded_exchanges[t].title))
		dlg.reset().add_line(dlg.ml("this is what i have available for you...").schoices(aval_choices))
		var choice := await dlg.speak_choice()
		if choice == &"bye":
			dlg.reset().add_line(dlg.ml("goodbye, then."))
			await dlg.speak_choice()
			break
		else:
			var exchange: GlassExchange = loaded_exchanges.values().filter(func(a: GlassExchange) -> bool: return a.title == choice)[0]
			dlg.reset()
			for line in exchange.description.split("\n", false):
				dlg.add_line(dlg.ml(line))
			dlg.add_line(dlg.ml("all i want in exchange is " + str(exchange.gold_required) + " gold."))
			await dlg.speak_choice()
			if exchange.has_input(inv):
				dlg.reset().add_line(dlg.ml("will you commit to this trade?").schoices(["yes", "no"]))
				choice = await dlg.speak_choice()
				if choice == &"yes":
					dlg.reset().add_line(dlg.ml("the pact is sealed, then."))
					await dlg.speak_choice()
					exchange.exchange(inv)
					animation_player.play(&"activate")
					remove_from_group(&"forest_curiosities")
					active = true
					break
			else:
				dlg.reset().add_line(dlg.ml("but, you don't have enough gold."))
				await dlg.speak_choice()


func _pick_random_exchanges() -> void:
	trades.clear()
	for i in 3:
		var key: StringName = loaded_exchanges.keys().pick_random()
		if key in trades:
			continue
		trades.append(key)


static func _kn() -> String:
	return "yellow_column"
