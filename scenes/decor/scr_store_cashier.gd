extends RefCounted
class_name StoreCashier

# cashier dialogue and interaction logic
# copied over from old greg i think

signal finished
signal dothething

var cashier := "nice"


func speak():
	if cashier == "dead": return
	var dat := DAT.A
	var unpaid_items : Array = dat.get("unpaid_items", [])
	
	# welcome and tutorial dialogue when not buying anything
	if unpaid_items.size() < 1:
		var cashier_welcomed : bool = DAT.get_data("cashier_%s_welcomed" % cashier, false)
		var transactions_done : int = DAT.get_data("%s_transactions_done" % cashier, 0)
		var silver_spent : int = DAT.get_data("%s_silver_spent" % cashier, 0)
		var profit_stolen : int = DAT.get_data("%s_profit_stolen" % cashier, 0)
		var friend_score : float = silver_spent * pow(transactions_done, 2) - pow(profit_stolen, 1.6)
		if not cashier_welcomed:
			SOL.dialogue("cashier_%s_welcome" % cashier)
			DAT.set_data("cashier_%s_welcomed" % cashier, true)
		else:
			if Math.inrange(friend_score, -10, 201):
				SOL.dialogue("cashier_%s_tutorial" % cashier)
			elif Math.inrange(friend_score, 201, 21000):
				SOL.dialogue("cashier_%s_chat_notfriends" % cashier)
			elif Math.inrange(friend_score, 21001, 100_000_000_000_000):
				SOL.dialogue_box.dial_concat("cashier_%s_chat" % cashier, 11, [silver_spent])
				SOL.dialogue("cashier_%s_chat" % cashier)
			else:
				SOL.dialogue("cashier_%s_tutorial" % cashier)
		
		finished.emit()
		return
	
	# dialogue if we're buying something
	var price := 0
	var silver = dat.get("silver", 0)
	for p in unpaid_items: # tallying price
		var item_price = DAT.get_item(p).price
		price += item_price
	if silver >= price:
		# inject the price into the cashier's dialogue
		SOL.dialogue_box.dial_concat("cashier_%s_tally" % cashier, 0, [price])
		SOL.dialogue("cashier_%s_tally" % cashier) # state the price
		await SOL.dialogue_closed
		# buy automatically
		DAT.set_data("silver", silver - price) # deduct money
		DAT.incri("%s_silver_spent" % cashier, price)
		for p in unpaid_items: # add unpaid items to real inventory
			DAT.get_character(DAT.get_data("party", ["greg"]).front()).inventory.append(p)
		unpaid_items.clear()
		SOL.call_deferred("dialogue", "cashier_%s_finish" % cashier) # thanks
		DAT.incri("%s_transactions_done" % cashier, 1)
	else: # not enough silver
		SOL.dialogue_box.dial_concat("cashier_%s_tally_poor" % cashier, 0, [price])
		SOL.dialogue("cashier_%s_tally_poor" % cashier)
		await SOL.dialogue_closed
		unpaid_items.clear()
	finished.emit()


# if trying to waltz out while having unpaid items
func warn() -> void:
	if cashier == "dead": return
	var stolen_profit := 0
	for i in DAT.get_data("unpaid_items", []):
		var price := DAT.get_item(i).price
		stolen_profit += price
	if stolen_profit < 1: return
	if cashier == "nice":
		# just warn you
		if Math.inrange(stolen_profit, 10, 99):
			SOL.dialogue("cashier_nice_notinterrupt")
		elif Math.inrange(stolen_profit, 100, 199):
			SOL.dialogue_box.dial_concat("cashier_nice_interrupt", 2, [stolen_profit])
			SOL.dialogue("cashier_nice_interrupt")
		elif stolen_profit > 199:
			SOL.dialogue_box.dial_concat("cashier_nice_warning", 0, [stolen_profit])
			SOL.dialogue("cashier_nice_warning")
	else:
		# just murder you
		SND.play_song("")
		DAT.capture_player("cashier_revenge")
		SOL.dialogue_box.dial_concat("cashier_mean_notice", 3, [stolen_profit])
		SOL.dialogue_box.dial_concat("cashier_mean_notice_repeat", 1, [stolen_profit])
		SOL.dialogue("cashier_mean_notice" + addrepeat())
		await SOL.dialogue_closed
		dothething.emit()


func addrepeat() -> String:
	# if you've gotten the cutscene already it should be shorter
	# not fully/goodly implemented
	if DAT.get_data("mean_cashier_saw_you_steal", false):
		return "_repeat"
	return ""
