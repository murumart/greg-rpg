extends BattleEnemy

const TUTORIAL_PROGRESS_LINES := ["zerma_fight_2_attack_zerma",
	"zerma_fight_3_item_greg_pocket_candy", "zerma_fight_4_spirit_zerma",
	"zerma_fight_4_spirit_greg", "zerma_fight_5_else", "zerma_fight_6_attack_zerma"]
const DISABLE_SELF_HARM_LINES := ["zerma_fight_3_attack_zerma",
	"zerma_fight_3_attack_greg", "zerma_fight_4_attack_zerma",
	"zerma_fight_4_attack_greg"]

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


func hurt(amount: float, gender: int) -> void:
	if character.health - _hurt_damage(amount, gender) <= 0:
		var prev := ignore_my_finishes
		ignore_my_finishes = false
		for x in 100:
			use_item(&"gummy_worm", self)
		ignore_my_finishes = prev
		character.health += 121831293
	super(amount, gender)


func _on_player_act_finished() -> void:
	var last_action := get_la()
	var last_action_type := last_action.get("type") as String
	var target := get_la_parm("target") as BattleActor
	var dialogue_key := ""
	dialogue_key = "zerma_fight_%s_%s_%s" % [progress, last_action_type,
			target.character.name_in_file if target else ""]
	if last_action_type == "item":
		if SOL.dialogue_exists(dialogue_key + "_" + get_la_parm("item")):
			dialogue_key += "_" + get_la_parm("item")
	if not SOL.dialogue_exists(dialogue_key):
		dialogue_key = "zerma_fight_%s_else" % progress
	await get_tree().process_frame
	SOL.dialogue(dialogue_key)
	# he will attack you at this point so you have a reason to use healing
	if dialogue_key == "zerma_fight_2_attack_zerma":
		await SOL.dialogue_closed
		SOL.dialogue_open = true
		await get_tree().create_timer(0.5).timeout
		attack(battle_reference.party[0])
		await get_tree().create_timer(1.0).timeout
		SOL.dialogue("zerma_fight_2_he_attacks")
		await SOL.dialogue_closed
	# gives you a status effect
	if (dialogue_key == "zerma_fight_4_spirit_greg"
			or dialogue_key == "zerma_fight_4_spirit_zerma"):
		battle_reference.attack_button.disabled = false
		await SOL.dialogue_closed
		ignore_my_finishes = true
		SOL.dialogue_open = true
		await get_tree().create_timer(0.5).timeout
		use_item(&"medkit", reference_to_opposing_array.front())
		await get_tree().create_timer(1.0).timeout
		SOL.dialogue("zerma_fight_4_status_effect")
		await SOL.dialogue_closed
	# add crittalbe
	if (dialogue_key == "zerma_fight_5_else"
			or dialogue_key == "zerma_fight_6_else"
			or dialogue_key == "zerma_fight_6_attack_greg"):
		reference_to_opposing_array.front().crittable.append(self)
	# if we can progress the dialogue
	if dialogue_key in TUTORIAL_PROGRESS_LINES:
		progress += 1
	# disabling self harm
	if dialogue_key in DISABLE_SELF_HARM_LINES:
		battle_reference.attack_button.disabled = true
	if progress == 3:
		if battle_reference.party[0].character.inventory.count(&"pocket_candy") <= 0:
			battle_reference.party[0].character.inventory.append(&"pocket_candy")
	# ending the battle
	if progress > 6:
		await SOL.dialogue_closed
		DAT.set_data("zerma_fought", true)
		DAT.set_data("intro_progress", 3)
		battle_reference.check_end(true)


func get_la() -> Dictionary:
	return battle_reference.action_history.back()


func get_la_parm(key: String) -> Variant:
	return battle_reference.action_history.back().get("parameters", {}).get(key)
