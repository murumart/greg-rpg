extends BattleEnemy

var battle_reference: Battle

var progress := 0


func _ready() -> void:
	remove_from_group("battle_actors")
	if LTS.get_current_scene() is Battle:
		battle_reference = LTS.get_current_scene()
		battle_reference.player_finished_acting.connect(_on_player_act_finished)
	super._ready()
	progress = 2
	SOL.dialogue("zerma_fight_1")


func act() -> void:
	super.act()
	turn_finished()


func _on_player_act_finished() -> void:
	var dialogue_key := "zerma_fight_%s_%s_%s" % [progress, get_la().get("type"), get_la_parm("target").character.name_in_file if get_la_parm("target") else ""]
	if not dialogue_key in SOL.dialogue_box.dialogues_dict.keys():
		dialogue_key = "zerma_fight_%s_else" % progress
	await get_tree().process_frame
	SOL.dialogue(dialogue_key)
	# he will attack you at this point so you have a reason to use healing
	if dialogue_key == "zerma_fight_2_attack_zerma":
		await SOL.dialogue_closed
		SOL.set_deferred("dialogue_open", true)
		await get_tree().create_timer(0.5)
		attack(battle_reference.party[0])
		await get_tree().create_timer(0.5)
		SOL.dialogue("zerma_fight_2_he_attacks")
		await SOL.dialogue_closed
	# if we can progress the dialogue
	if dialogue_key in ["zerma_fight_2_attack_zerma",  "zerma_fight_3_item_greg", "zerma_fight_4_spirit_zerma", "zerma_fight_4_spirit_greg", "zerma_fight_4_else"]:
		progress += 1
	# disabling self harm
	if dialogue_key in ["zerma_fight_3_attack_zerma", "zerma_fight_3_attack_greg", "zerma_fight_4_attack_zerma", "zerma_fight_4_attack_greg"]:
		battle_reference.attack_button.disabled = true
	if progress == 3:
		if battle_reference.party[0].character.inventory.is_empty():
			battle_reference.party[0].character.inventory.append("pocket_candy")
	# ending the battle
	if progress > 4:
		await SOL.dialogue_closed
		DAT.set_data("zerma_fought", true)
		DAT.set_data("intro_progress", 3)
		battle_reference.check_end(true)


func get_la() -> Dictionary:
	return battle_reference.action_history.back()


func get_la_parm(key: String) -> Variant:
	return battle_reference.action_history.back().get("parameters", {}).get(key)
