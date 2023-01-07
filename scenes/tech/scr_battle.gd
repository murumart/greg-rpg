extends Node2D
class_name Battle

# the battle screen. what did you expect?

enum Doings {NOTHING = -1, ATTACK, SPIRIT, ITEM}
var doing : Doings = Doings.NOTHING

@onready var panel : Panel = $UI/Panel
@onready var reference_button : Button = $UI/ReferenceButton
@onready var description_text : RichTextLabel = $%DescriptionText
@onready var actor_containers : Array = [$UI/Panel/ScreenActorSelect/ScrollContainer/ListContainer/Left, $UI/Panel/ScreenActorSelect/ScrollContainer/ListContainer/Right]
@onready var enemies_node : Node2D = $Enemies
@onready var party_node : Node2D = $Party

var actors : Array[BattleActor]
var party : Array[BattleActor]
var enemies : Array[BattleActor]

var current_guy : BattleActor


func _ready() -> void:
	for e in enemies_node.get_children():
		e.queue_free()
	for a in party_node.get_children():
		a.queue_free()
	$%AttackButton.selected.connect(set_description)
	$%AttackButton.pressed.connect(_on_attack_pressed)
	$%SpiritButton.selected.connect(set_description)
	$%SpiritButton.pressed.connect(_on_spirit_pressed)
	$%ItemButton.selected.connect(set_description)
	$%ItemButton.pressed.connect(_on_item_pressed)
	load_battle()
	open_main_actions_screen(current_guy.character)


func load_battle(options := {}) -> void:
	add_party_member(0)
	add_enemy(preload("res://scenes/characters/enemies/scn_enemy_bike_ghost.tscn").instantiate())
	add_enemy(preload("res://scenes/characters/enemies/scn_enemy_bike_ghost.tscn").instantiate())
	current_guy = party[0]


func add_enemy(node: BattleActor, ally := false) -> void:
	if ally:
		party_node.add_child(node)
	else:
		enemies_node.add_child(node)
	enemies.append(node)
	actors.append(node)


func add_party_member(id: int) -> void:
	var party_member = preload("res://scenes/tech/scn_battle_actor.tscn").instantiate()
	party_member.character_id = id
	party_node.add_child(party_member)
	actors.append(party_member)
	party.append(party_member)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if $%ScreenActorSelect.visible:
			open_main_actions_screen(current_guy.character)
			doing = Doings.NOTHING


func load_reference_buttons(array: Array, containers: Array, clear := true) -> void:
	if clear:
		for container in containers:
			for c in container.get_children():
				if c.is_connected("return_reference", _reference_button_pressed):
					print("disconnecting %s from signal" % c.name)
					c.disconnect("return_reference", _reference_button_pressed)
				c.queue_free()
	var container_nr := 0
	for i in array.size():
		var refbutton := reference_button.duplicate()
		refbutton.reference = array[i]
		refbutton.connect("return_reference", _reference_button_pressed)
		containers[container_nr].add_child(refbutton)
		refbutton.show()
		container_nr = wrapi(container_nr + 1, 0, containers.size())


func _reference_button_pressed(reference) -> void:
	match doing:
		Doings.ATTACK:
			current_guy.attack(reference)


func open_main_actions_screen(character : Character) -> void:
	$%ScreenActorSelect.hide()
	$%CharPortrait.texture = character.portrait
	$%CharInfo1.text = str("%s\nlvl %s" % [character.name, character.level])
	$%CharInfo2.text = str("atk: %s\ndef: %s\nspd: %s\nhp: %s/%s\nsp: %s/%s" % [roundi(character.attack), roundi(character.defense), roundi(character.speed), roundi(character.health), roundi(character.max_health), roundi(character.magic), roundi(character.max_magic)])
	$%ScreenMainActions.show()
	$%AttackButton.grab_focus()


func open_actor_list_screen() -> void:
	$%ScreenMainActions.hide()
	load_reference_buttons(party, actor_containers, true)
	load_reference_buttons(enemies, actor_containers, false)
	$%ScreenActorSelect.show()


func _on_attack_pressed() -> void:
	open_actor_list_screen()
	doing = Doings.ATTACK
	if actor_containers[0].get_children().size() > 0:
		actor_containers[0].get_child(0).grab_focus()


func _on_spirit_pressed() -> void:
	pass


func _on_item_pressed() -> void:
	pass


func set_description(text: String) -> void:
	description_text.text = text


func resize_panel(new_y: int) -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(panel, "size:y", panel.size.y + new_y, 0.2)
	tw.tween_property(panel, "position:y", panel.position.y - new_y, 0.2)

