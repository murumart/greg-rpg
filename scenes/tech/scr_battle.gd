extends Node2D
class_name Battle

# the battle screen. what did you expect?
# battles consist of actors lowering their cooldown based on their speed
# (speedier = faster cooldown) and then acting, during which time
# others cannot act. once one team is defeated, the battle ends.

signal player_finished_acting

# this is the default for testing
var load_options : BattleInfo = BattleInfo.new().\
set_enemies(["stray_pet", "chimney"]).\
set_music("foreign_fauna").set_party(["greg",]).set_rewards(load("res://resources/battle_rewards/res_test_reward.tres")).set_background("sun").set_death_reason("solar")

var play_victory_music := true

const SCREEN_SIZE := Vector2i(160, 120)
const MAX_PARTY_MEMBERS := 3
const MAX_ENEMIES := 6

const BACK_PITCH := 0.75

enum Teams {PARTY, ENEMIES}

# states of the battle
enum Doings {NOTHING = -1, WAITING, ATTACK, SPIRIT, SPIRIT_NAME, ITEM_MENU, ITEM, END, DONE}
var doing := Doings.NOTHING:
	set(to):
		doing = to
		print("doing ", Doings.find_key(to))
var action_history := []

var loading_battle := true

# many nodes

@onready var ui := $UI

@onready var panel : Panel = $UI/Panel
@onready var reference_button := preload("res://scenes/tech/scn_reference_button.tscn")
@onready var description_text : RichTextLabel = $%DescriptionText
@onready var list_containers : Array = [$UI/Panel/ScreenListSelect/ScrollContainer/ListContainer/Left, $UI/Panel/ScreenListSelect/ScrollContainer/ListContainer/Right]
@onready var item_list_container : Array = [$UI/Panel/ScreenItemSelect/ScrollContainer/List]
@onready var enemies_node : Node2D = $Enemies
@onready var party_node : Node2D = $Party
@onready var update_timer : Timer = $SlowUpdateTimer
@onready var background_container : Node2D = $Background

@onready var screen_list_select := $%ScreenListSelect
@onready var screen_item_select := $%ScreenItemSelect
@onready var item_info_label := $UI/Panel/ScreenItemSelect/ItemInfoLabel
@onready var screen_party_info := $%ScreenPartyInfo
@onready var screen_spirit_name := $%ScreenSpiritName
@onready var screen_end := %ScreenEnd
@onready var victory_text := %VictoryText
@onready var defeat_text := %DefeatText
@onready var attack_button := $%AttackButton
@onready var spirit_button := $%SpiritButton
@onready var item_button := $%ItemButton
@onready var selected_guy_display := $%SelectedGuy
@onready var log_text := $%LogText
@onready var spirit_name := $%SpiritName
@onready var spirit_speak_timer := %SpiritSpeakTimer
@onready var spirit_speak_timer_progress := %SpiritSpeakTimerProgress
var spirit_speak_timer_wait := 2.0

@onready var party_member_panel_container := $UI/Panel/ScreenPartyInfo/Container

var held_item_id : String = ""

# storing battle members
var actors : Array[BattleActor]
var dead_actors : Array[BattleActor]
var party : Array[BattleActor]
var dead_party : Array[BattleActor]
var ever_has_been_party : Array[BattleActor]
var enemies : Array[BattleActor]
var dead_enemies : Array[BattleActor]

var xp_pool := 0:
	set(to):
		xp_pool = to
		print("set xp pool to ", to)

var listening_to_player_input := false
var current_guy : BattleActor
var loaded_spirits := {}
var current_target : BattleActor

var death_reason := "default"
var battle_rewards : BattleRewards

var f := 0

@export var enable_testing_cheats := false
@export_group("Cheat Stats")
@export var party_cheat_levelup := 0
@export var party_cheat_health := 0.0
@export var party_cheat_magic := 0.0
@export var party_cheat_attack := 0.0
@export var party_cheat_defense := 0.0
@export var party_cheat_speed := 0.0
@export var party_add_spirits : Array[String] = []
@export var party_add_items : Array[String] = []


func _ready() -> void:
	update_timer.timeout.connect(_on_update_timer_timeout)
	update_timer.start()
	for e in enemies_node.get_children():
		e.queue_free()
	for a in party_node.get_children():
		a.queue_free()
	attack_button.selected.connect(set_description)
	attack_button.pressed.connect(_on_attack_pressed)
	spirit_button.selected.connect(set_description)
	spirit_button.pressed.connect(_on_spirit_pressed)
	item_button.selected.connect(set_description)
	item_button.pressed.connect(_on_item_pressed)
	spirit_name.text_changed.connect(_on_spirit_name_changed)
	spirit_name.text_submitted.connect(_on_spirit_name_submitted)
	spirit_speak_timer.timeout.connect(_on_spirit_speak_timer_timeout)
	await get_tree().process_frame
	load_battle(load_options)
	set_actor_states(BattleActor.States.COOLDOWN, true)
	open_party_info_screen()
	check_end()
	DAT.death_reason = death_reason


func _physics_process(_delta: float) -> void:
	f += 1
	match doing:
		Doings.SPIRIT_NAME:
			# match the timer with the progress bar
			spirit_speak_timer_progress.value = remap(spirit_speak_timer.time_left, 0.0, spirit_speak_timer_wait, 0.0, 100.0)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_0:
		ui.visible = ! event.is_pressed()
		if not event.is_pressed():
			attack_button.grab_focus()
	if not listening_to_player_input: return
	if event.is_action_pressed("ui_cancel"):
		go_back_a_menu()
	if event.is_action_pressed("ui_accept"):
		if doing == Doings.DONE:
			# leave the battle
			LTS.gate_id = LTS.GATE_EXIT_BATTLE
			var looper :Array[BattleActor]= []
			looper.append_array(party)
			looper.append_array(dead_party)
			for p in looper:
				p.offload_character()
			LTS.level_transition(LTS.ROOM_SCENE_PATH % DAT.get_data("current_room", "test_room"))
			set_process_unhandled_key_input(false)
		else:
			var _deferred := bool(OPT.get_opt("list_button_focus_deferred"))
#			if screen_list_select.visible:
#				if list_containers[0].get_children().size() > 0:
#					if deferred: list_containers[0].get_child(0).call_deferred("grab_focus")
#					else: list_containers[0].get_child(0).grab_focus()
#			elif screen_item_select.visible:
#				if item_list_container[0].get_children().size() > 0:
#					if deferred: item_list_container[0].get_child(0).call_deferred("grab_focus")
#					else: item_list_container[0].get_child(0).grab_focus()


func load_battle(info: BattleInfo) -> void:
	# second argument of info.get_ is the default value
	for m in info.get_("party", DAT.get_data("party", ["greg"])):
		add_party_member(m)
	for e in info.enemies:
		add_enemy(e)
	set_background(info.background)
	death_reason = info.death_reason
	SND.play_song(info.music, 1.0, {start_volume = 0, play_from_beginning = true})
	battle_rewards = info.get_("rewards", BattleRewards.new()).duplicate(true)
	if not battle_rewards:
		battle_rewards = load("res://resources/battle_rewards/res_default_reward.tres").duplicate(true)
	apply_cheats()
	log_text.append_text(info.get_("start_text", "%s lunges at you!" % enemies.front().actor_name) + "\n")
	play_victory_music = info.victory_music
	loading_battle = false


func set_actor_states(to: BattleActor.States, only_party := false) -> void:
	if only_party:
		for i in get_tree().get_nodes_in_group("battle_actors"):
			if i in party:
				i.call("set_state", to)
	else:
		get_tree().call_group("battle_actors", "set_state", to)


func add_actor(node: BattleActor, team: Teams) -> void:
	if team == Teams.PARTY:
		if party.size() > MAX_PARTY_MEMBERS:
			push_error("too many party members")
			return
	node.reference_to_actor_array = actors
	node.message.connect(_on_message_received)
	node.act_requested.connect(_on_act_requested)
	node.act_finished.connect(_on_act_finished)
	node.died.connect(_on_actor_died)
	node.fled.connect(_on_actor_fled)
	node.teammate_requested.connect(_on_summon_enemy_requested)
	actors.append(node)
	match team:
		Teams.PARTY:
			party.append(node)
			ever_has_been_party.append(node)
			node.player_controlled = true
			node.player_input_requested.connect(_on_player_input_requested)
			node.reference_to_team_array = party
			node.reference_to_opposing_array = enemies
			party_node.add_child(node)
			party_member_panel_container.\
			get_child(party.find(node)).remote_transform.remote_path = node.get_path()
		Teams.ENEMIES:
			node.wait += 0.5
			enemies.append(node)
			node.reference_to_team_array = enemies
			node.reference_to_opposing_array = party
			enemies_node.add_child(node)


func add_enemy(character_id: String, ally := false) -> void:
	var character : Character = DAT.get_character(character_id)
	var node : BattleActor
	if DIR.enemy_scene_exists(character.name_in_file) and not ally:
		node = load(DIR.enemy_scene_path(character.name_in_file)).instantiate()
		node.load_character(character_id)
	else:
		node = preload("res://scenes/tech/scn_battle_enemy.tscn").instantiate()
		node.load_character(character_id)
		node.xp_multiplier = 1.0 if not loading_battle else 0.25
		if not ally:
			var sprite_new := Sprite2D.new()
			node.add_child(sprite_new)
			sprite_new.texture = preload("res://sprites/characters/battle/spr_enemy_battle.png")
			node.effect_center = Vector2i(0, -20)
	
	add_actor(node, Teams.ENEMIES if not ally else Teams.PARTY)
	
	arrange_enemies()


func add_party_member(id: String) -> void:
	var party_member : BattleActor = preload("res://scenes/tech/scn_battle_actor.tscn").instantiate()
	party_member.load_character(id)
	
	add_actor(party_member, Teams.PARTY)
	
	update_party()


func arrange_enemies():
	if enemies.size() < 1: return
	var scree := SCREEN_SIZE.x - 20
	var tw := create_tween().set_parallel(true)
	for e in len(enemies):
		# space enemies evenly on the screen
		var to : float = roundf(-scree/2.0 + scree/float(len(enemies))*(e+1) - scree/float(len(enemies))/2.0)
		tw.tween_property(enemies[e], "global_position:x", to, 0.2)
		enemies[e].global_position.y = 0
		if e % 2 != 0:
			enemies[e].scale.x = -1.0


func set_background(id: String) -> void:
	var path := DIR.battle_background_scene_path(id)
	if DIR.battle_background_scene_exists(id):
		background_container.add_child(load(path).instantiate())
	else:
		background_container.add_child(load("res://scenes/battle_backgrounds/scn_bikeghost.tscn").instantiate())


# update the panel visuals
func update_party() -> void:
	for child in party_member_panel_container.get_children():
		child.hide()
	for i in ever_has_been_party.size():
		var member : BattleActor = ever_has_been_party[i]
		party_member_panel_container.get_child(i).update(member)
		party_member_panel_container.get_child(i).show()


func go_back_a_menu() -> void:
	match doing:
		Doings.NOTHING:
			attack_button.grab_focus()
		Doings.ATTACK:
			open_main_actions_screen()
			SND.menusound(BACK_PITCH)
		Doings.ITEM_MENU:
			open_main_actions_screen()
			SND.menusound(BACK_PITCH)
		Doings.ITEM:
			doing = Doings.ITEM_MENU
			open_list_screen()
			SND.menusound(BACK_PITCH)
		Doings.SPIRIT:
			open_main_actions_screen()
			SND.menusound(BACK_PITCH)
		Doings.SPIRIT_NAME:
			doing = Doings.SPIRIT
			open_list_screen()
			SND.menusound(BACK_PITCH)
	highlight_selected_enemy()
	erase_floating_spirits()


# fill menus with buttons (menus to select actors and items and such)
func load_reference_buttons(array: Array, containers: Array, clear := true) -> void:
	if clear:
		for container in containers:
			for c in container.get_children():
				c.queue_free()
	var container_nr := 0
	if current_guy.is_confused():
		array.shuffle()
		containers.shuffle()
	for i in array.size():
		var reference = array[i]
		var refbutton := reference_button.instantiate()
		refbutton.reference = reference
		if reference is BattleActor:
			refbutton.text = reference.actor_name
		elif reference is String and doing == Doings.ITEM_MENU:
			refbutton.text = DAT.get_item(reference).name
		else:
			refbutton.text = str(reference)
		refbutton.connect("return_reference", _reference_button_pressed)
		refbutton.connect("selected_return_reference", _on_button_reference_received)
		containers[container_nr].add_child(refbutton)
		refbutton.show()
		container_nr = wrapi(container_nr + 1, 0, containers.size())
	container_nr = 0
	await get_tree().process_frame
	for i in containers.size():
		var c = containers[i]
		for j in c.get_child_count():
			var k = c.get_child(j)
			if j == 0:
				k.focus_neighbor_top = containers[wrapi(i - 1, 0, containers.size())].get_child(-1).get_path()
			if j + 1 >= c.get_child_count():
				k.focus_neighbor_bottom = containers[wrapi(i + 1, 0, containers.size())].get_child(0).get_path()


# something is selected
func _reference_button_pressed(reference) -> void:
	if SOL.dialogue_open: return
	if if_end(): return
	match doing:
		Doings.ATTACK:
			current_guy.attack(reference)
			listening_to_player_input = false
			append_action_history("attack", {"target": reference})
			open_party_info_screen()
		Doings.SPIRIT:
			current_target = reference
			open_spirit_name_screen()
			SND.play_sound(preload("res://sounds/snd_gui.ogg"), {"bus": "ECHO", "pitch": 0.8})
		Doings.ITEM_MENU:
			doing = Doings.ITEM
			held_item_id = reference
			open_list_screen()
		Doings.ITEM:
			listening_to_player_input = false
			current_guy.use_item(held_item_id, reference)
			append_action_history("item", {"target": reference, "item": held_item_id})
			open_party_info_screen()


# descriptions for items and such
func _on_button_reference_received(reference) -> void:
	if doing == Doings.ATTACK or doing == Doings.SPIRIT or doing == Doings.ITEM:
		selected_guy_display.update(reference)
		highlight_selected_enemy(reference)
	if doing == Doings.ITEM_MENU:
		item_info_label.text = str(DAT.get_item(reference).get_effect_description(),"\n[color=#888888]", DAT.get_item(reference).description)


# some actor wants to act!
func _on_act_requested(actor: BattleActor) -> void:
	if if_end(): return
	open_party_info_screen()
	set_actor_states(BattleActor.States.IDLE)
	actor.act()


# some actor has finished their act
func _on_act_finished(actor: BattleActor) -> void:
	if if_end(): return
	if actor.player_controlled:
		player_finished_acting.emit()
	open_party_info_screen()
	check_end()
	await get_tree().create_timer(0.25).timeout
	set_actor_states(BattleActor.States.COOLDOWN)


# some actor has been killed
func _on_actor_died(actor: BattleActor) -> void:
	if if_end(): return
	if actor in party:
		dead_party.append(party.pop_at(party.find(actor)))
	if actor in enemies:
		actor = actor as BattleEnemy
		dead_enemies.append(enemies.pop_at(enemies.find(actor)))
		xp_pool += actor.character.level * actor.xp_multiplier
	dead_actors.append(actors.pop_at(actors.find(actor)))
	arrange_enemies()
	check_end()
	await get_tree().process_frame
	update_party()


# some actor has fled the fight
func _on_actor_fled(actor: BattleActor) -> void:
	if if_end(): return
	if actor in party:
		pass
	if actor in enemies:
		dead_enemies.append(enemies.pop_at(enemies.find(actor)))
		xp_pool += roundi(actor.character.level * 0.33)
	dead_actors.append(actors.pop_at(actors.find(actor)))
	arrange_enemies()
	check_end()
	await get_tree().process_frame
	update_party()


# more enemies are requested by a spirit perhaps
func _on_summon_enemy_requested(actor: BattleActor, req: String) -> void:
	if actor in enemies:
		if enemies.size() < MAX_ENEMIES:
			add_enemy(req)
			_on_message_received("%s joined the fight" % DAT.get_character(req).name)
		else:
			_on_message_received("%s did not fit into the fight." % DAT.get_character(req).name)
	else:
		if party.size() < MAX_PARTY_MEMBERS:
			add_party_member(req)
			_on_message_received("%s joined the fight" % DAT.get_character(req).name)
		else:
			_on_message_received("%s did not fit into the fight." % DAT.get_character(req).name)


func check_end(force := false) -> void:
	if if_end(): return
	var end_condition := party.size() < 1 or enemies.size() < 1
	if end_condition or force:
		doing = Doings.END
		SND.play_song("")
		open_end_screen(party.size() > 0)


func _on_message_received(msg: String) -> void:
	log_text.append_text(msg + "\n")


# when a player-controllect character requests act
func _on_player_input_requested(actor: BattleActor) -> void:
	current_guy = actor
	open_main_actions_screen()
	listening_to_player_input = true


# choice between fighting, spirits and items
func open_main_actions_screen() -> void:
	var info := $%CurrentInfo
	held_item_id = ""
	current_target = null
	screen_item_select.hide()
	screen_list_select.hide()
	screen_party_info.hide()
	screen_spirit_name.hide()
	screen_end.hide()
	resize_panel(44)
	# sparkle on, it's wednesday! don't forget to be yourself!
	if Time.get_date_dict_from_system().weekday == Time.WEEKDAY_WEDNESDAY and randf() <= 0.05:
		attack_button.text = "slay"
	else:
		attack_button.text = "tussle"
	# set the current guy actor node position to the portrait's position
	# so that visual effects get displayed in a more correct position
	party_member_panel_container.get_child(party.find(current_guy)).\
	remote_transform.update_position = false
	current_guy.global_position = info.remote_transform.global_position
	info.update(current_guy)
	$%CharInfo1.text = str("%s\nlvl %s" % [current_guy.character.name, current_guy.character.level])
	$%CharInfo2.text = str("atk: %s\ndef: %s\nspd: %s\nhp: %s/%s\nsp: %s/%s" % [roundi(current_guy.get_attack()), roundi(current_guy.get_defense()), roundi(current_guy.get_speed()), roundi(current_guy.character.health), roundi(current_guy.character.max_health), roundi(current_guy.character.magic), roundi(current_guy.character.max_magic)])
	$%ScreenMainActions.show()
	attack_button.grab_focus()
	erase_floating_spirits()
	match doing:
		Doings.NOTHING:
			attack_button.grab_focus()
		Doings.ATTACK:
			attack_button.grab_focus()
		Doings.ITEM_MENU:
			item_button.grab_focus()
		Doings.SPIRIT:
			spirit_button.grab_focus()
	doing = Doings.NOTHING


# item/actor listing screens
func open_list_screen() -> void:
	$%ScreenMainActions.hide()
	screen_item_select.hide()
	screen_list_select.hide()
	screen_party_info.hide()
	screen_spirit_name.hide()
	screen_end.hide()
	match doing:
		Doings.ATTACK:
			var array := []
			array.append_array(enemies)
			array.append_array(party)
			Math.load_reference_buttons(array, list_containers, _reference_button_pressed, _on_button_reference_received)
			screen_list_select.show()
		Doings.ITEM_MENU:
			Math.load_reference_buttons(current_guy.character.inventory, item_list_container, _reference_button_pressed, _on_button_reference_received, {"item": true, "custom_pass_function": item_names})
			screen_item_select.show()
		Doings.ITEM:
			var array := []
			array.append_array(party)
			array.append_array(enemies)
			Math.load_reference_buttons(actors, list_containers, _reference_button_pressed, _on_button_reference_received)
			screen_list_select.show()
		Doings.SPIRIT:
			Math.load_reference_buttons(actors, list_containers, _reference_button_pressed, _on_button_reference_received)
			screen_list_select.show()
			load_floating_spirits()
	resize_panel(60)
	await get_tree().process_frame # <---- of course this needs to be here
	var deferred : int = OPT.get_opt("list_button_focus_deferred")
	if screen_list_select.visible:
		if list_containers[0].get_children().size() > 0:
			if deferred: list_containers[0].get_child(0).call_deferred("grab_focus")
			else: list_containers[0].get_child(0).grab_focus()
	elif screen_item_select.visible:
		if item_list_container[0].get_children().size() > 0:
			if deferred: item_list_container[0].get_child(0).call_deferred("grab_focus")
			else: item_list_container[0].get_child(0).grab_focus()


# the one between player acts
func open_party_info_screen() -> void:
	listening_to_player_input = false
	for i in party_member_panel_container.get_children():
		i.remote_transform.update_position = true
	doing = Doings.NOTHING
	held_item_id = ""
	$%ScreenMainActions.hide()
	screen_item_select.hide()
	screen_list_select.hide()
	screen_party_info.show()
	screen_spirit_name.hide()
	screen_end.hide()
	resize_panel(25)
	update_party()
	highlight_selected_enemy()
	erase_floating_spirits()


func open_spirit_name_screen() -> void:
	spirit_name.add_theme_font_size_override("font_size", 16)
	doing = Doings.SPIRIT_NAME
	held_item_id = ""
	resize_panel(4, 0.1)
	$%ScreenMainActions.hide()
	spirit_name.text = ""
	spirit_name.editable = true
	screen_item_select.hide()
	screen_list_select.hide()
	screen_party_info.hide()
	screen_spirit_name.show()
	spirit_speak_timer.paused = false
	spirit_speak_timer.start(spirit_speak_timer_wait)
	for i in current_guy.character.spirits:
		var spirit : Spirit = DAT.get_spirit(i)
		loaded_spirits[spirit.name] = i
	spirit_name.grab_focus()


# you didn't type the spirit name fast enough
func _on_spirit_speak_timer_timeout() -> void:
	listening_to_player_input = false
	SND.play_sound(preload("res://sounds/snd_error.ogg"), {pitch = 0.7, bus = "ECHO"})
	spirit_name.text = "moment passed"
	spirit_name.modulate = Color(2, 0.2, 0.4)
	spirit_name.editable = false
	append_action_history("spirit_fail")
	await get_tree().create_timer(0.5).timeout
	current_guy.turn_finished()
	open_party_info_screen()


func _on_spirit_name_changed(to: String) -> void:
	to = to.to_lower() # no uppercase
	spirit_name.text = to
	spirit_name.caret_column = to.length()
	spirit_name.add_theme_font_size_override("font_size", 16)
	if to.length() > 12:
		spirit_name.add_theme_font_size_override("font_size", 8)
	if to in loaded_spirits.keys():
		_on_spirit_name_submitted(to)
		return
	
	SND.play_sound(preload("res://sounds/snd_gui.ogg"), {"bus": "ECHO", "pitch": [1.0, 1.0, 1.18921, 1.7818].pick_random()})
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(spirit_name, "modulate", Color(0.8, 0.8, 8.0, 2.0), 0.1)
	tw.tween_property(spirit_name, "modulate", Color(1, 1, 1, 1), 0.3)


func _on_spirit_name_submitted(submission: String) -> void:
	listening_to_player_input = false
	get_viewport().gui_release_focus()
	spirit_speak_timer.paused = true
	if submission in loaded_spirits.keys():
		spirit_name.editable = false
		var spirit_id = loaded_spirits[submission]
		var spirit := DAT.get_spirit(spirit_id)
		if spirit.cost <= current_guy.character.magic:
			SND.play_sound(preload("res://sounds/spirit/snd_spirit_name_found.ogg"))
			var tw := create_tween().set_trans(Tween.TRANS_QUART)
			tw.tween_property(spirit_name, "modulate", Color(2, 2, 2, 10), 1.5)
			
			await get_tree().create_timer(1.5).timeout
			current_guy.use_spirit(spirit_id, current_target)
			append_action_history("spirit", {"spirit": spirit_id, "target": current_target})
			open_party_info_screen()
			return
		else:
			spirit_name.text = "not enough magic!"
			
	SND.play_sound(preload("res://sounds/snd_error.ogg"), {bus = "ECHO"})
	append_action_history("spirit_fail")
	await get_tree().create_timer(0.5).timeout
	current_guy.turn_finished()
	open_party_info_screen()
	erase_floating_spirits()


# horrible function
func open_end_screen(victory: bool) -> void:
	if screen_end.visible: return
	screen_end.show()
	set_actor_states(BattleActor.States.IDLE)
	screen_item_select.hide()
	screen_list_select.hide()
	screen_spirit_name.hide()
	victory_text.visible = victory
	defeat_text.visible = !victory
	await get_tree().create_timer(1.0).timeout
	screen_party_info.show()
	victory_text.speak_text()
	if victory:
		resize_panel(60)
		SND.play_song("victory", 10, {start_volume = 0.0, play_from_beginning = true})
		var xp_reward := Reward.new()
		xp_reward.type = BattleRewards.Types.EXP
		xp_reward.property = str(xp_pool)
		battle_rewards.rewards.append(xp_reward)
		if battle_rewards.rewards.size() > 0:
			_grant_rewards()
			print("awaiting rewards grant")
			await battle_rewards.granted
		print("awaiting dialogue close")
		await SOL.dialogue_closed
		doing = Doings.DONE
		listening_to_player_input = true
	else:
		if DAT.death_reason == "default":
			DAT.death_reason = death_reason
		await get_tree().create_timer(1.0).timeout
		SOL.clear_vfx()
		LTS.to_game_over_screen()


func _grant_rewards() -> void:
	await get_tree().process_frame
	battle_rewards.grant()

# main screen buttons wired to these
func _on_attack_pressed() -> void:
	if SOL.dialogue_open: return
	doing = Doings.ATTACK
	open_list_screen()
	SND.menusound()


func _on_spirit_pressed() -> void:
	if SOL.dialogue_open: return
	if current_guy.character.spirits.size() < 1:
		SND.menusound(0.3)
		set_description("this one has no spirits.")
		return
	doing = Doings.SPIRIT
	open_list_screen()
	SND.menusound()
	spirit_name.modulate = Color(1, 1, 1, 1)


func _on_item_pressed() -> void:
	if SOL.dialogue_open: return
	doing = Doings.ITEM_MENU
	open_list_screen()
	SND.menusound()


func set_description(text: String) -> void:
	description_text.text = text
	if text.ends_with("%s"):
		description_text.text = text % "hands"
		if current_guy.character.weapon:
			description_text.text = text % DAT.get_item(current_guy.character.weapon).name


func highlight_selected_enemy(enemy: BattleActor = null) -> void:
	for e in enemies:
		e.modulate = Color(1, 1, 1, 1)
		e.position.y = 0
	if not (enemy and enemy is BattleEnemy): return
	enemy.modulate = Color(1.2, 1.2, 1.2, 1.3)
	var tw := create_tween()
	tw.tween_property(enemy, "position:y", -2, 0.1)


func resize_panel(new_y: int, wait := 0.2) -> void:
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	tw.tween_property(panel, "size:y", new_y, wait)
	tw.tween_property(panel, "position:y", SCREEN_SIZE.y - new_y, wait)


# update the party faces not every frame
func _on_update_timer_timeout() -> void:
	if screen_party_info.visible:
		update_party()


func apply_cheats() -> void:
	if not enable_testing_cheats: return
	if LTS.gate_id: return
	if DAT.seconds > 1: return
	print("applying cheats")
	for i in party:
		i.character.level_up(party_cheat_levelup)
		for n in party_cheat_levelup:
			if DAT.get_levelup_spirit(n):
				i.character.spirits.append(DAT.get_levelup_spirit(n))
		i.character.health = i.character.max_health
		i.character.magic = i.character.max_magic
		if party_cheat_attack:
			i.character.attack = party_cheat_attack
		if party_cheat_defense:
			i.character.defense = party_cheat_defense
		if party_cheat_speed:
			i.character.speed = party_cheat_speed
		if party_cheat_health:
			i.character.max_health = party_cheat_health
			i.character.health = party_cheat_health
		if party_cheat_magic:
			i.character.max_magic = party_cheat_magic
			i.character.magic = party_cheat_magic
		if party_add_spirits:
			for j in party_add_spirits:
				i.character.spirits.append(j)
		if party_add_items:
			for j in party_add_items:
				i.character.inventory.append(j)


# load info from battle info
func _option_init(options := {}) -> void:
	load_options = options.get("battle_info")


# woh
func append_action_history(type: String, parameters := {}) -> void:
	var dict := {}
	dict["type"] = type
	dict["parameters"] = parameters
	dict["time"] = Time.get_time_string_from_system()
	action_history.append(dict)


func if_end() -> bool:
	return doing == Doings.END or doing == Doings.DONE


func load_floating_spirits() -> void:
	for i in current_guy.character.spirits:
		var s := SOL.vfx("spirit_name_hint", Vector2(), {spirit = i})
		s.add_to_group("floating_spirits")


func erase_floating_spirits() -> void:
	for i in get_tree().get_nodes_in_group("floating_spirits"):
		i.del()


func item_names(opt := {}) -> void:
	opt.button.text = DAT.get_item(opt.reference).name.left(13)

