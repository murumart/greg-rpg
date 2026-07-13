extends Control

const PARTY_MEMBER_BUTTON := preload("res://scenes/gui/menu/party_member_button.tscn")
const PartyMemberButtonType := preload("res://scenes/gui/menu/party_member_button.gd")
const ReferenceButtonType := preload("res://scenes/tech/scr_reference_button.gd")

enum State {
	CHOOSE_CHAR,
	CHAR_OPTIONS,
	INVENTORY,
	SPIRITS,
}

signal close_requested
signal skateboard_dequipped

@onready var party_members_container: VBoxContainer = $PartyMembers
@onready var character_options_parent: PanelContainer = $CharacterOptions
@onready var character_options_container: VBoxContainer = $CharacterOptions/CharacterOptionsContainer

var saving_disabled := false

var _state := State.CHOOSE_CHAR


func open() -> void:
	_state = State.CHOOSE_CHAR

	character_options_parent.hide()
	_load_party_members()

	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	show()


func close() -> void:
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
	hide()


func _load_party_members() -> void:
	var party := DAT.get_data("party", ["greg"]) as Array
	party_members_container.get_children().map(func(n: Node) -> void: n.free())
	var i := 0
	for p: StringName in party:
		var k := ResMan.get_character(p)
		var mb: PartyMemberButtonType = PARTY_MEMBER_BUTTON.instantiate()
		party_members_container.add_child(mb)
		mb.display(k)
		mb.pressed.connect(_party_member_selected.bind(i))
		i += 1
	(party_members_container.get_child(0) as PartyMemberButtonType).grab_focus.call_deferred()


func _party_member_selected(ix: int) -> void:
	assert(_state == State.CHOOSE_CHAR)
	_state = State.CHAR_OPTIONS
	_open_party_member_options_menu()
	for o: PartyMemberButtonType in party_members_container.get_children():
		o.disabled = true


func _open_party_member_options_menu() -> void:
	character_options_parent.show()
	(party_members_container.get_child(0) as PartyMemberButtonType).release_focus()
	(character_options_container.get_child(0) as ReferenceButtonType).grab_focus.call_deferred()
