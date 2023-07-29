class_name Exchange extends Resource
# every rpg needs a crafting system!!!!!!!!

enum Statements {CRITERIA, RETURNS}

@export var title := ""

@export var silver_required := 0
@export var input : Array[StringName] = []
@export var silver_granted := 0
@export var output : Array[StringName] = []


func exchange(inventory: Array) -> bool:
	print("exchanging!")
	var has_input := true
	for i in input:
		if not i in inventory:
			has_input = false
	if DAT.get_data("silver", 0) < silver_required:
		has_input = false
	if not has_input:
		SOL.dialogue("exchange_missing_input")
		return false
	SOL.dialogue("exchange_success")
	for i in input:
		inventory.erase(i)
	DAT.incri("silver", -silver_required)
	for i in output:
		inventory.append(i)
		SOL.dialogue_box.dial_concat("exchange_item", 0, [DAT.get_item(i).name])
		SOL.dialogue("exchange_item")
	if silver_granted:
		DAT.incri("silver", silver_granted)
		SOL.dialogue_box.dial_concat("exchange_silver", 0, [silver_granted])
		SOL.dialogue("exchange_silver")
	return true


func state(what: Statements) -> void:
	var informations := []
	# criterion strings
	if what == Statements.CRITERIA:
		if silver_required:
			informations.append("- %s silver" % silver_required)
		for i in input:
			informations.append("- %s" % DAT.get_item(i).name)
	elif what == Statements.RETURNS:
		if silver_granted:
			informations.append("- %s silver" % silver_granted)
		for i in output:
			informations.append("- %s" % DAT.get_item(i).name)
	
	# TITLE: this exchange requires: LB%s LB%s
	# SISU: %s LB%s LB%s
	var divisions := [[]]
	for i in informations.size():
		var criterion := informations[i] as String
		if i < 2: # divisions[0] is the title, only 2 %s
			divisions[0].append(criterion)
		else:
			if (i + 1) % 3 == 0: divisions.append([])
			divisions[floori((i + 1) / 3.0)].append(criterion)
	var dial_title := "exchange_criteria_title" if what == Statements.CRITERIA else "exchange_returns_title"
	for i in divisions.size():
		if i == 0:
			while divisions[i].size() < 2:
				divisions[i].append("") # need empty string to make %s disappear
			SOL.dialogue_box.dial_concat(dial_title, 0, divisions[i])
			SOL.dialogue(dial_title)
		else:
			while divisions[i].size() < 3:
				divisions[i].append("")
			SOL.dialogue_box.dial_concat("exchange_criteria_sisu", 0, divisions[i])
			SOL.dialogue("exchange_criteria_sisu")


func _to_string() -> String:
	return title


func set_input(to: Array) -> Exchange:
	input.clear()
	input.append_array(to)
	return self


func set_output(to: Array) -> Exchange:
	output.clear()
	output.append_array(to)
	return self

