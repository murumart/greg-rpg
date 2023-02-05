extends Node2D
class_name Battle

# the battle screen. what did you expect?

var load_options : BattleInfo = BattleInfo.new().set_enemies(["bike_ghost"])

const SCREEN_SIZE := Vector2i(160, 120)
const MAX_PARTY_MEMBERS := 3

const BACK_PITCH := 0.75

enum Teams {PARTY, ENEMIES}

enum Doings {NOTHING = -1, WAITING, ATTACK, SPIRIT, SPIRIT_NAME, ITEM_MENU, ITEM, END, DONE}
var doing := Doings.NOTHING

@onready var panel : Panel = $UI/Panel
@onready var reference_button : Button = $UI/ReferenceButton
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

var actors : Array[BattleActor]
var dead_actors : Array[BattleActor]
var party : Array[BattleActor]
var dead_party : Array[BattleActor]
var enemies : Array[BattleActor]
var dead_enemies : Array[BattleActor]

var current_guy : BattleActor
var loaded_spirits := {}
var current_target : BattleActor

var f := 0

@export var enable_testing_cheats := false
@export_group("Cheat Stats")
@export var party_cheat_levelup := 0
@export var party_cheat_health := 0.0
@export var party_cheat_magic := 0.0
@export var party_cheat_attack := 0.0
@export var party_cheat_defense := 0.0
@export var party_cheat_speed := 0.0


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


func _physics_process(_delta: float) -> void:
	f += 1
	match doing:
		Doings.SPIRIT_NAME:
			spirit_speak_timer_progress.value = remap(spirit_speak_timer.time_left, 0.0, spirit_speak_timer_wait, 0.0, 100.0)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		go_back_a_menu()
	if event.is_action_pressed("ui_accept"):
		if doing == Doings.DONE:
			LTS.gate_id = &"exit_battle"
			var looper :Array[BattleActor]= []
			looper.append_array(party)
			looper.append_array(dead_party)
			for p in looper:
				p.offload_character()
			LTS.level_transition("res://scenes/rooms/scn_room_test.tscn")
			set_process_unhandled_key_input(false)


func load_battle(info: BattleInfo) -> void:
	for m in info.get_("party", ["greg"]):
		add_party_member(m)
	for e in info.get_("enemies", []):
		add_enemy(e)
	set_background(info.get_("background", "bikeghost"))
	SND.play_song(info.get_("music", ""), 1.0, {start_volume = 0})
	apply_cheats()


func set_actor_states(to: BattleActor.States, only_party := false) -> void:
	if only_party:
		for i in get_tree().get_nodes_in_group("battle_actors"):
			if i in party:
				i.call("set_state", to)
		return
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
	actors.append(node)
	match team:
		Teams.PARTY:
			party.append(node)
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
	print(path)
	if DIR.file_exists(path):
		background_container.add_child(load(path).instantiate())
	else:
		background_container.add_child(load("res://scenes/battle_backgrounds/scn_bikeghost.tscn").instantiate())


func update_party() -> void:
	for child in party_member_panel_container.get_children():
		child.hide()
	var array := []
	array.append_array(party)
	array.append_array(dead_party)
	for i in array.size():
		var member : BattleActor = array[i]
		party_member_panel_container.get_child(i).update(member)
		party_member_panel_container.get_child(i).show()


func go_back_a_menu() -> void:
	match doing:
		Doings.NOTHING:
			pass
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


func load_reference_buttons(array: Array, containers: Array, clear := true) -> void:
	if clear:
		for container in containers:
			for c in container.get_children():
				if c.is_connected("return_reference", _reference_button_pressed):
					c.disconnect("return_reference", _reference_button_pressed)
				if c.is_connected("selected_return_reference", _on_button_reference_received):
					c.disconnect("selected_return_reference", _on_button_reference_received)
				c.queue_free()
	var container_nr := 0
	if current_guy.is_confused():
		array.shuffle()
		containers.shuffle()
	for i in array.size():
		var reference = array[i]
		var refbutton := reference_button.duplicate()
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


func _reference_button_pressed(reference) -> void:
	match doing:
		Doings.ATTACK:
			current_guy.attack(reference)
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
			current_guy.use_item(held_item_id, reference)
			open_party_info_screen()


func _on_button_reference_received(reference) -> void:
	if doing == Doings.ATTACK or doing == Doings.SPIRIT or doing == Doings.ITEM:
		selected_guy_display.update(reference)
		highlight_selected_enemy(reference)
	if doing == Doings.ITEM_MENU:
		item_info_label.text = str(DAT.get_item(reference).get_effect_description(),"\n[color=#888888]", DAT.get_item(reference).description)


func _on_act_requested(actor: BattleActor) -> void:
	open_party_info_screen()
	print(actor, " requested act")
	set_actor_states(BattleActor.States.IDLE)
	actor.act()


func _on_act_finished(_actor: BattleActor) -> void:
	if doing == Doings.END: return
	set_actor_states(BattleActor.States.COOLDOWN)
	open_party_info_screen()
	check_end()


func _on_actor_died(actor: BattleActor) -> void:
	print(actor, " died")
	if actor in party:
		dead_party.append(party.pop_at(party.find(actor)))
	if actor in enemies:
		dead_enemies.append(enemies.pop_at(enemies.find(actor)))
	dead_actors.append(actors.pop_at(actors.find(actor)))
	arrange_enemies()
	check_end()
	await get_tree().process_frame
	update_party()


func check_end() -> void:
	if doing == Doings.END: return
	var end_condition := party.size() < 1 or enemies.size() < 1
	if end_condition:
		doing = Doings.END
		SND.play_song("")
		open_end_screen(party.size() > 0)


func _on_message_received(msg: String) -> void:
	log_text.append_text(msg + "\n")


func _on_player_input_requested(actor: BattleActor) -> void:
	print(actor, " wants player input")
	current_guy = actor
	open_main_actions_screen()


func open_main_actions_screen() -> void:
	held_item_id = ""
	current_target = null
	screen_item_select.hide()
	screen_list_select.hide()
	screen_party_info.hide()
	screen_spirit_name.hide()
	screen_end.hide()
	resize_panel(44)
	$%CharPortrait.texture = current_guy.character.portrait
	$%CharInfo1.text = str("%s\nlvl %s" % [current_guy.character.name, current_guy.character.level])
	$%CharInfo2.text = str("atk: %s\ndef: %s\nspd: %s\nhp: %s/%s\nsp: %s/%s" % [roundi(current_guy.get_attack()), roundi(current_guy.get_defense()), roundi(current_guy.get_speed()), roundi(current_guy.character.health), roundi(current_guy.character.max_health), roundi(current_guy.character.magic), roundi(current_guy.character.max_magic)])
	$%ScreenMainActions.show()
	attack_button.grab_focus()
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
			load_reference_buttons(array, list_containers, true)
			screen_list_select.show()
		Doings.ITEM_MENU:
			load_reference_buttons(current_guy.character.inventory, item_list_container, true)
			screen_item_select.show()
		Doings.ITEM:
			var array := []
			array.append_array(party)
			array.append_array(enemies)
			load_reference_buttons(array, list_containers, true)
			screen_list_select.show()
		Doings.SPIRIT:
			load_reference_buttons(actors, list_containers, true)
			screen_list_select.show()
	resize_panel(60)
	await get_tree().process_frame # <---- of course this needs to be here
	if screen_list_select.visible:
		if list_containers[0].get_children().size() > 0:
			list_containers[0].get_child(0).call_deferred("grab_focus")
	elif screen_item_select.visible:
		if item_list_container[0].get_children().size() > 0:
			item_list_container[0].get_child(0).grab_focus()


func open_party_info_screen() -> void:
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


func open_spirit_name_screen() -> void:
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


func _on_spirit_speak_timer_timeout() -> void:
	SND.play_sound(preload("res://sounds/snd_error.ogg"), {pitch = 0.7, bus = "ECHO"})
	spirit_name.text = "moment passed"
	spirit_name.modulate = Color(2, 0.2, 0.4)
	spirit_name.editable = false
	await get_tree().create_timer(0.5).timeout
	current_guy.turn_finished()
	open_party_info_screen()


func open_end_screen(victory: bool) -> void:
	if screen_end.visible: return
	print("ENDING BATTLE: ", "victory" if victory else "defeat")
	set_actor_states(BattleActor.States.IDLE)
	screen_item_select.hide()
	screen_list_select.hide()
	screen_spirit_name.hide()
	screen_end.show()
	victory_text.visible = victory
	defeat_text.visible = !victory
	await get_tree().create_timer(1.0).timeout
	resize_panel(60)
	screen_party_info.show()
	victory_text.speak_text()
	if victory:
		SND.play_song("victory", 10, {start_volume = 0.0, play_from_beginning = true})
		var xp_pool : int = 0
		for i in dead_enemies:
			xp_pool += i.character.level
		print("xp pool: ", xp_pool)
		var looper := []
		looper.append_array(party)
		looper.append_array(dead_party)
		for i in looper:
			i.character.add_experience(xp_pool)
			await get_tree().process_frame
			if SOL.speaking:
				await SOL.dialogue_closed
		print("doings should be done now")
		doing = Doings.DONE
	else:
		defeat_text.speak_text()
		SND.play_song("defeat", 10, {start_volume = 0.0})


func _on_attack_pressed() -> void:
	doing = Doings.ATTACK
	open_list_screen()
	SND.menusound()


func _on_spirit_pressed() -> void:
	if current_guy.character.spirits.size() < 1:
		SND.menusound(0.3)
		set_description("this one has no spirits.")
		return
	doing = Doings.SPIRIT
	open_list_screen()
	SND.menusound()
	spirit_name.modulate = Color(1, 1, 1, 1)


func _on_item_pressed() -> void:
	doing = Doings.ITEM_MENU
	open_list_screen()
	SND.menusound()


func _on_spirit_name_changed(to: String) -> void:
	if to in loaded_spirits.keys():
		_on_spirit_name_submitted(to)
		return
	
	SND.play_sound(preload("res://sounds/snd_gui.ogg"), {"bus": "ECHO", "pitch": [1.0, 1.0, 1.18921, 1.7818].pick_random()})
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(spirit_name, "modulate", Color(1.1, 1.1, 8.0, 1.1), 0.1)
	tw.tween_property(spirit_name, "modulate", Color(1, 1, 1, 1), 0.3)


func _on_spirit_name_submitted(submission: String) -> void:
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
			open_party_info_screen()
			return
		else:
			spirit_name.text = "not enough magic!"
	SND.play_sound(preload("res://sounds/snd_error.ogg"), {bus = "ECHO"})
	await get_tree().create_timer(0.5).timeout
	current_guy.turn_finished()
	open_party_info_screen()


func set_description(text: String) -> void:
	description_text.text = text


func highlight_selected_enemy(enemy:BattleActor = null) -> void:
	for e in enemies:
		e.modulate = Color(1, 1, 1, 1)
		e.position.y = 0
	if enemy and enemy is BattleEnemy:
		enemy.modulate = Color(1.2, 1.2, 1.2, 1.3)
		var tw := create_tween()
		tw.tween_property(enemy, "position:y", -2, 0.1)


func resize_panel(new_y: int, wait := 0.2) -> void:
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	tw.tween_property(panel, "size:y", new_y, wait)
	tw.tween_property(panel, "position:y", SCREEN_SIZE.y - new_y, wait)


func _on_update_timer_timeout() -> void:
	if screen_party_info.visible:
		update_party()


func apply_cheats() -> void:
	if not enable_testing_cheats: return
	print("applying cheats")
	for i in party:
		i.character.level_up(party_cheat_levelup)
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


func _option_init(options := {}) -> void:
	load_options = options.get("battle_info")
