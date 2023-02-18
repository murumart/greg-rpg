extends RefCounted
class_name StoreCashier


func speak():
	var cashier = "nice"
	var dat := DAT.A
	var unpaid_items : Array = dat.get("unpaid_items", [])
	var dialogues = SOL.dialogue_box.dialogues_dict
	
	# welcome and tutorial dialogue when not buying anything
	if unpaid_items.size() < 1:
		if not DAT.get_data("cashier_welcomed", false):
			SOL.dialogue("cashier_%s_welcome" % cashier)
			DAT.set_data("cashier_welcomed", true)
		else:
			SOL.dialogue("cashier_%s_tutorial" % cashier)
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
		for p in unpaid_items: # add unpaid items to real inventory
			DAT.get_character(DAT.A.get("party", ["greg"]).front()).inventory.append(p)
		unpaid_items.clear()
		SOL.call_deferred("dialogue", "cashier_%s_finish" % cashier) # thanks
	else: # not enough silver
		SOL.dialogue_box.dial_concat("cashier_%s_tally_poor" % cashier, 0, [price])
		SOL.dialogue("cashier_%s_tally_poor" % cashier)
		await SOL.dialogue_closed
		unpaid_items.clear()
		

