extends Node2D
class_name Battle

# the battle screen. what did you expect?

const SCREEN_SIZE := Vector2i(160, 120)
const PARTY_MAX_SIZE := 3

const BACK_PITCH := 0.75

enum Doings {NOTHING = -1, WAITING, ATTACK, SPIRIT, SPIRIT_NAME, ITEM_MENU, ITEM}
var doing := Doings.NOTHING

@onready var panel : Panel = $UI/Panel
@onready var reference_button : Button = $UI/ReferenceButton
@onready var description_text : RichTextLabel = $%DescriptionText
@onready var list_containers : Array = [$UI/Panel/ScreenListSelect/ScrollContainer/ListContainer/Left, $UI/Panel/ScreenListSelect/ScrollContainer/ListContainer/Right]
@onready var item_list_container : Array = [$UI/Panel/ScreenItemSelect/ScrollContainer/List]
@onready var enemies_node : Node2D = $Enemies
@onready var party_node : Node2D = $Party
@onready var update_timer : Timer = $SlowUpdateTimer

@onready var screen_list_select := $%ScreenListSelect
@onready var screen_item_select := $%ScreenItemSelect
@onready var screen_party_info := $%ScreenPartyInfo
@onready var screen_spirit_name := $%ScreenSpiritName
@onready var attack_button := $%AttackButton
@onready var spirit_button := $%SpiritButton
@onready var item_button := $%ItemButton
@onready var selected_guy_display := $%SelectedGuy
@onready var log_text := $%LogText
@onready var spirit_name := $%SpiritName

@onready var party_member_panel_container := $UI/Panel/ScreenPartyInfo/Container

var held_item_id : int = -1

var actors : Array[BattleActor]
var party : Array[BattleActor]
var enemies : Array[BattleActor]

var current_guy : BattleActor
var loaded_spirits := {}
var current_target : BattleActor

var f := 0


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
	load_battle()
	set_actor_states(BattleActor.States.COOLDOWN)
	open_party_info_screen()


func _physics_process(_delta: float) -> void:
	f += 1
	#print(f)


func load_battle(options := {}) -> void:
	add_party_member(0)
	add_party_member(2)
	add_enemy(preload("res://scenes/characters/enemies/scn_enemy_bike_ghost.tscn").instantiate())
	add_enemy(preload("res://scenes/characters/enemies/scn_enemy_bike_ghost.tscn").instantiate())
	for i in party.size():
		pass
	current_guy = party[0]


func set_actor_states(to: BattleActor.States) -> void:
	get_tree().call_group("battle_actors", "set_state", to)


func add_enemy(node: BattleActor, ally := false) -> void:
	if ally:
		party.append(node)
		node.player_controlled = true
		node.player_input_requested.connect(_on_player_input_requested)
		node.reference_to_team_array = party
		node.reference_to_opposing_array = enemies
		party_node.add_child(node)
	else:
		enemies.append(node)
		node.reference_to_team_array = enemies
		node.reference_to_opposing_array = party
		enemies_node.add_child(node)
	node.reference_to_actor_array = actors
	node.message.connect(_on_message_received)
	node.act_requested.connect(_on_act_requested)
	node.act_finished.connect(_on_act_finished)
	node.wait += 0.02
	actors.append(node)
	arrange_enemies()


func add_party_member(id: int) -> void:
	var party_member : BattleActor = preload("res://scenes/tech/scn_battle_actor.tscn").instantiate()
	party_member.character_id = id
	party_member.reference_to_actor_array = actors
	party_member.reference_to_opposing_array = enemies
	party_member.reference_to_team_array = party
	party_member.message.connect(_on_message_received)
	party_member.act_requested.connect(_on_act_requested)
	party_member.act_finished.connect(_on_act_finished)
	party_member.player_controlled = true
	party_member.player_input_requested.connect(_on_player_input_requested)
	actors.append(party_member)
	party.append(party_member)
	party_node.add_child(party_member)
	party_member_panel_container.get_child(party.find(party_member)).remote_transform.remote_path = party_member.get_path()
	update_party()


func arrange_enemies():
	var scree := SCREEN_SIZE.x - 20
	for e in len(enemies):
		# space enemies evenly on the screen
		enemies[e].global_position.x = (-scree/2.0 + scree/float(len(enemies))*(e+1) - scree/float(len(enemies))/2.0)
		enemies[e].global_position.y = 0
		if e % 2 != 0:
			enemies[e].scale.x = -1.0


func update_party() -> void:
	for child in party_member_panel_container.get_children():
		child.hide()
	for i in party.size():
		var member : BattleActor = party[i]
		party_member_panel_container.get_child(i).update(member)
		party_member_panel_container.get_child(i).show()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
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
	for i in array.size():
		var reference = array[i]
		var refbutton := reference_button.duplicate()
		refbutton.reference = reference
		if reference is BattleActor:
			refbutton.text = reference.actor_name
		elif reference is int and doing == Doings.ITEM_MENU:
			refbutton.text = DAT.get_item(reference).name
		else:
			refbutton.text = str(reference)
		refbutton.connect("return_reference", _reference_button_pressed)
		refbutton.connect("selected_return_reference", _on_button_reference_received)
		containers[container_nr].add_child(refbutton)
		refbutton.show()
		container_nr = wrapi(container_nr + 1, 0, containers.size())


func _reference_button_pressed(reference) -> void:
	print(reference, " pressed")
	match doing:
		Doings.ATTACK:
			current_guy.attack(reference)
			open_party_info_screen()
		Doings.SPIRIT:
			print("we talk spirit now")
			current_target = reference
			open_spirit_name_screen()
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


func _on_act_requested(actor: BattleActor) -> void:
	open_party_info_screen()
	print(actor, " requested act")
	set_actor_states(BattleActor.States.IDLE)
	actor.act()


func _on_act_finished(_actor: BattleActor) -> void:
	set_actor_states(BattleActor.States.COOLDOWN)
	open_party_info_screen()


func _on_message_received(msg: String) -> void:
	log_text.append_text(msg + "\n")


func _on_player_input_requested(actor: BattleActor) -> void:
	print(actor, " wants player input")
	current_guy = actor
	open_main_actions_screen()


func open_main_actions_screen() -> void:
	held_item_id = -1
	current_target = null
	screen_item_select.hide()
	screen_list_select.hide()
	screen_party_info.hide()
	screen_spirit_name.hide()
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
	match doing:
		Doings.ATTACK:
			load_reference_buttons(enemies, list_containers, true)
			load_reference_buttons(party, list_containers, false)
			screen_list_select.show()
		Doings.ITEM_MENU:
			load_reference_buttons(current_guy.character.inventory, item_list_container, true)
			screen_item_select.show()
		Doings.ITEM:
			load_reference_buttons(party, list_containers, true)
			load_reference_buttons(enemies, list_containers, false)
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
	held_item_id = -1
	$%ScreenMainActions.hide()
	screen_item_select.hide()
	screen_list_select.hide()
	screen_party_info.show()
	screen_spirit_name.hide()
	resize_panel(25)
	update_party()


func open_spirit_name_screen() -> void:
	held_item_id = -1
	resize_panel(4, 0.1)
	$%ScreenMainActions.hide()
	spirit_name.text = ""
	spirit_name.editable = true
	screen_item_select.hide()
	screen_list_select.hide()
	screen_party_info.hide()
	screen_spirit_name.show()
	for i in current_guy.character.spirits:
		var spirit : Spirit = DAT.get_spirit(i)
		loaded_spirits[spirit.name] = i
	spirit_name.grab_focus()


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
	print(submission)
	if submission in loaded_spirits.keys():
		spirit_name.editable = false
		var spirit_id = loaded_spirits[submission]
		var spirit := DAT.get_spirit(spirit_id)
		if spirit.cost <= current_guy.character.magic:
			SND.play_sound(preload("res://sounds/spirit/snd_spirit_name_found.ogg"))
			var tw := create_tween().set_trans(Tween.TRANS_QUART)
			tw.tween_property(spirit_name, "modulate", Color(2, 2, 2, 60), 1.5)
			
			await get_tree().create_timer(1.5).timeout
			current_guy.use_spirit(spirit_id, current_target)
			open_party_info_screen()
		else:
			SND.play_sound(preload("res://sounds/snd_error.ogg"))
			spirit_name.text = "not enough magic!"
			await get_tree().create_timer(0.5).timeout
			current_guy.turn_finished()
			open_party_info_screen()


func set_description(text: String) -> void:
	description_text.text = text


func resize_panel(new_y: int, wait := 0.2) -> void:
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	tw.tween_property(panel, "size:y", new_y, wait)
	tw.tween_property(panel, "position:y", SCREEN_SIZE.y - new_y, wait)


func _on_update_timer_timeout() -> void:
	if screen_party_info.visible:
		update_party()

