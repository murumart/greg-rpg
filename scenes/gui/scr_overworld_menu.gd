extends Control

# overworld menu - items and character information and such

signal close_requested
signal skateboard_dequipped

const TIME_AFTER_WARN_SAVE := 300

const MEM_INFO_DEF_SIZE := Vector2(63, 71)
const MEM_INFO_DEF_POS := Vector2(2, 25)
const MEM_INFO_BIG_SIZE := Vector2(63, 94)
const MEM_INFO_BIG_POS := Vector2(2, 2)

enum Doings {PARTY, INNER, USING}
var doing := Doings.PARTY

@onready var tab_container := $Panel/TabContainer
var current_tab := 0

@onready var mem_portrait := $Panel/InfoPanel/MemberInfo/Portrait
@onready var mem_infotext := $Panel/InfoPanel/MemberInfo/MainInfoText

@onready var item_spirit_tabs := $Panel/ItemSpiritTabs
@onready var item_container := $Panel/ItemSpiritTabs/items/Scroll/ItemsContainer
@onready var used_spirit_container := $Panel/ItemSpiritTabs/spirits/UsedSpiritsPanel/Scroll/UsedSpiritContainer
@onready var unused_spirit_container := $Panel/ItemSpiritTabs/spirits/UnusedSpiritsPanel/Scroll/UnusedSpiritContainer
@onready var silver_counter := $Panel/ItemSpiritTabs/items/SilverCounterLabel

@onready var using_menu := $UsingMenu
@onready var using_portraits := $UsingMenu/Panel/Portraits
@onready var using_label := $UsingMenu/Label
var using_menu_choice := 0
var using_item: String

@onready var save_warning_label := $SaveWarningLabel

@onready var reference_button := $ReferenceButton
var saving_disabled := false


func _ready() -> void:
	using_menu.hide()
	update_tabs()


# ugly
func _unhandled_input(event: InputEvent) -> void:
	# open the save menu (no idea why this is controlled here)
	if Input.is_action_just_pressed("quick_save") or Input.is_action_just_pressed("quick_load"):
		if DAT.player_capturers.is_empty():
			if not saving_disabled:
				SOL.save_menu(Input.is_action_just_pressed("quick_load"))
	if not visible: return
	get_viewport().set_input_as_handled()
	# going back a menu level
	if event.is_action_pressed("ui_cancel"):
		match doing:
			Doings.INNER:
				doing = Doings.PARTY
				SND.menusound(0.8)
			Doings.USING:
				doing = Doings.INNER
				SND.menusound(0.8)
				using_menu.hide()
				grab_item_focus()
			Doings.PARTY:
				close_requested.emit()
	match doing:
		Doings.PARTY:
			
			item_spirit_tabs.modulate = Color.from_string("#888888", Color.WHITE)
			var old_tab = current_tab
			current_tab = wrapi(current_tab + roundi(Input.get_axis("ui_left", "ui_right")), 0, party_size())
			if current_tab != old_tab: SND.menusound(1.3)
			update_tabs()
			
			if event.is_action_pressed("ui_accept"):
				doing = Doings.INNER
				SND.menusound()
				await get_tree().process_frame
				call_deferred("grab_item_focus")
		Doings.INNER:
			item_spirit_tabs.modulate = Color.from_string("#ffffff", Color.WHITE)
			var old_tab = item_spirit_tabs.current_tab
			item_spirit_tabs.current_tab = wrapi(item_spirit_tabs.current_tab + roundi(Input.get_axis("ui_left", "ui_right")), 0, item_spirit_tabs.get_tab_count())
			if item_spirit_tabs.current_tab != old_tab:
				SND.menusound(1.47)
				grab_item_focus()
				
		Doings.USING:
			var item := DAT.get_item(using_item) as Item
			var old_choice := using_menu_choice
			using_menu_choice = wrapi(using_menu_choice + roundi(Input.get_axis("ui_left", "ui_right")), 0, party_size() + 1)
			update_using_portraits()
			if using_menu_choice != party_size():
				if item.use in Item.USES_EQUIPABLE:
					using_label.text = "equipping " + item.name
				else:
					using_label.text = "using " + item.name
			else:
				using_label.text = "delete " + item.name + "?"
			if old_choice != using_menu_choice:
				SND.menusound(1.35)
			if event.is_action_pressed("ui_accept"):
				
				if item_spirit_tabs.current_tab == 0:
					if using_menu_choice == party_size(): # trashcan
						party(current_tab).inventory.erase(using_item)
						SND.play_sound(preload("res://sounds/trashbin.ogg"))
					else:
						party(using_menu_choice).handle_item(using_item)
						
						if item.consume_on_use:
							party(current_tab).inventory.erase(using_item)
						if not item.use in Item.USES_EQUIPABLE:
							SND.play_sound((item.play_sound if item.play_sound
							else preload("res://sounds/use_item.ogg")),
							{volume = -15})
				
				elif item_spirit_tabs.current_tab == 1:
					var spirit: Spirit = DAT.get_spirit(using_item)
					if not party(current_tab).magic >= spirit.cost:
						SND.play_sound(load("res://sounds/error.ogg"))
						using_label.text = "not enough magic!"
					else:
						party(using_menu_choice).handle_payload(spirit.payload)
						party(current_tab).magic = party(current_tab).magic - spirit.cost
						if spirit.animation:
							SOL.vfx(spirit.animation, Vector2())
				
				doing = Doings.INNER
				load_items()
				load_spirits()
				using_menu.hide()
				await get_tree().process_frame
				grab_item_focus()


# tabs in question are the items-spirits tabs
func update_tabs() -> void:
	var i := 0
	for tab in tab_container.get_children():
		tab = tab as Panel
		tab.z_index = -int(not current_tab == i)
		tab.visible = i < party_size()
		tab.get_child(0).text = party(i).name if i < party_size() else ""
		
		i += 1
	
	load_items()
	load_spirits()
	if doing == Doings.PARTY:
		side_load_character_data()


# print character data to the side
func side_load_character_data() -> void:
	var charct: Character = party(current_tab)
	mem_portrait.texture = charct.portrait
	mem_infotext.text = str("
[color=#ff88ff]lvl: %s[/color]
[color=#ff88aa]exp: %s/%s[/color]
[color=#ff8888]atk: %s[/color]
[color=#ffaa88]def: %s[/color]
[color=#ffff88]spd: %s[/color]
[color=#44ff44]hp: %s/%s[/color]
[color=#88ffff]sp: %s/%s[/color]" % [charct.level, (str(charct.experience) if charct.level < 99 else "en"), (str(charct.xp2lvl(charct.level)) if charct.level < 99 else "ough"), charct.get_stat("attack"), charct.get_stat("defense"), charct.get_stat("speed"), roundi(charct.health), roundi(charct.max_health), roundi(charct.magic), roundi(charct.max_magic)])
	mem_infotext.size = MEM_INFO_DEF_SIZE
	mem_infotext.position = MEM_INFO_DEF_POS


# print item data to the side
func side_load_item_data(id: String) -> void:
	var item: Item = DAT.get_item(id)
	mem_portrait.texture = item.texture
	mem_infotext.text = str("[color=#888888]", item.description + "\n", "[/color]")
	mem_infotext.text += item.get_effect_description()
	if party(current_tab).inventory.find(id) < 2:
		if (id == party(current_tab).armour):
			mem_infotext.append_text("equipped")
		if (id == party(current_tab).weapon):
			mem_infotext.append_text("equipped")
	mem_infotext.size = MEM_INFO_DEF_SIZE
	mem_infotext.position = MEM_INFO_DEF_POS


# print spirit data to the side
func side_load_spirit_data(id: String) -> void:
	var spirit: Spirit = DAT.get_spirit(id)
	mem_portrait.texture = null
	mem_infotext.text = str("[color=#888888]", spirit.description + "\n", "[/color]")
	mem_infotext.text += spirit.get_effect_description()
	mem_infotext.text += str("[color=#008888]","cost: ", spirit.cost, "[/color]\n")
	if id in party(current_tab).unused_sprits:
		mem_infotext.append_text("\n[color=#888888]unused. select to equip")
	else:
		mem_infotext.append_text("\n[color=#888888]select to unequip")
	mem_infotext.size = MEM_INFO_BIG_SIZE
	mem_infotext.position = MEM_INFO_BIG_POS


# load items from the inventory of current character 
# + weapon and armour at the top of the list
func load_items() -> void:
	var item_array := []
	item_array.append_array(party(current_tab).inventory)
	item_array.sort()
	if DAT.get_data("player_move_mode", 0) == 1:
		item_array.push_front(&"skateboard")
	if party(current_tab).armour:
		item_array.push_front(party(current_tab).armour)
	if party(current_tab).weapon:
		item_array.push_front(party(current_tab).weapon)
	
	Math.load_reference_buttons_groups(item_array, [item_container], _reference_button_pressed, _on_button_reference_received, {"item": true, "custom_pass_function": item_names})
	var silver_text := "p. silver:\n" if party_size() > 1 else "silver: "
	silver_counter.text = str(silver_text, DAT.get_data("silver", 0))


func item_names(opt := {}) -> void:
	# for displaying armour and weapons in char inventory
	var equipped: int = 0 + (
		int(opt.reference == party(current_tab).armour) +
		int(opt.reference == party(current_tab).weapon) +
		int(opt.reference == &"skateboard" and
			DAT.get_data("player_move_mode", 0) == 1)
	)
	if equipped:
		opt.button.modulate = Color(1.0, 0.6, 0.3)
		opt.button.set_meta(&"equipped", true)
	if DAT.get_data("player_move_mode", 0) == 1 and opt.reference == &"skateboard":
		opt.button.modulate = Color(1.0, 0.6, 0.3)
		opt.button.set_meta(&"equipped", true)
	var count: int = party(current_tab).inventory.count(opt.reference) + equipped
	opt.button.text = str(
		str(count, "x ") if count > 1 else "",
		DAT.get_item(opt.reference).name
		).left(12)


func spirit_names(opt := {}) -> void:
	opt.button.text = DAT.get_spirit(opt.reference).name.left(12)


# display the character's used and unused spirits
func load_spirits() -> void:
	var spirit_array := []
	var unused_spirit_array := []
	spirit_array.append_array(party(current_tab).spirits)
	unused_spirit_array.append_array(party(current_tab).unused_sprits)
	Math.load_reference_buttons(spirit_array, [used_spirit_container], _reference_button_pressed, _on_button_reference_received, {"spirit": true, "adjust_focus": false, "custom_pass_function": spirit_names})
	Math.load_reference_buttons(unused_spirit_array, [unused_spirit_container], _reference_button_pressed, _on_button_reference_received, {"spirit": true, "adjust_focus": false, "custom_pass_function": spirit_names})


func grab_item_focus() -> void:
	if item_container.get_child_count() > 0 and item_spirit_tabs.current_tab == 0:
		item_container.get_child(0).call_deferred("grab_focus")
	if used_spirit_container.get_child_count() > 0 and item_spirit_tabs.current_tab == 1:
		used_spirit_container.get_child(0).call_deferred("grab_focus")
	elif unused_spirit_container.get_child_count() > 0 and item_spirit_tabs.current_tab == 1:
		unused_spirit_container.get_child(0).call_deferred("grab_focus")


func load_using_menu() -> void:
	get_viewport().gui_release_focus()
	for p in using_portraits.get_child_count():
		var child := using_portraits.get_child(p)
		if party(p) is Character:
			child.texture = party(p).portrait
		else:
			child.hide()
		if p == 3:
			child.show()
	using_menu_choice = current_tab
	using_menu.show()


# highlighting the portraits in the using item menu level
func update_using_portraits() -> void:
	var c := 0
	for i in using_portraits.get_child_count():
		using_portraits.get_child(i).modulate = Color(1, 1, 1, 1)
		if not using_portraits.get_child(i).visible:
			continue
		if using_menu_choice == c:
			using_portraits.get_child(i).modulate = Color(1.4, 1.4, 1.4, 1)
		c += 1


func _reference_button_pressed(reference) -> void:
	if reference in party(current_tab).inventory:
		if item_spirit_tabs.current_tab == 0 and doing == Doings.INNER:
			if (reference == party(current_tab).armour):
				party(current_tab).armour = ""
				party(current_tab).inventory.append(reference)
				SND.menusound(0.4)
				load_items()
				await get_tree().process_frame
				call_deferred("grab_item_focus")
				return
			if (reference == party(current_tab).weapon):
				party(current_tab).weapon = ""
				party(current_tab).inventory.append(reference)
				SND.menusound(0.4)
				load_items()
				await get_tree().process_frame
				call_deferred("grab_item_focus")
				return
		if reference == &"skateboard" and DAT.get_data("player_move_mode", 0) == 1:
			DAT.set_data("player_move_mode", 0)
			skateboard_dequipped.emit()
			party(current_tab).inventory.append(reference)
			SND.menusound(0.4)
			load_items()
			await get_tree().process_frame
			call_deferred("grab_item_focus")
			return
		doing = Doings.USING
		using_item = reference
		load_using_menu()
	if item_spirit_tabs.current_tab == 1 and doing == Doings.INNER:
		if reference in party(current_tab).unused_sprits:
			if used_spirit_container.get_child_count() < DAT.MAX_SPIRITS:
				party(current_tab).unused_sprits.erase(reference)
				party(current_tab).spirits.append(reference)
				load_spirits()
				SND.play_sound(preload("res://sounds/spirit/spirit_equip.ogg"))
				await get_tree().process_frame
				grab_item_focus()
			else:
				SND.play_sound(load("res://sounds/error.ogg"), {"volume": -10})
				mem_infotext.text = "can only equip %s spirits at a time" % DAT.MAX_SPIRITS
		elif reference in party(current_tab).spirits:
			party(current_tab).spirits.erase(reference)
			party(current_tab).unused_sprits.append(reference)
			load_spirits()
			SND.play_sound(preload("res://sounds/spirit/spirit_dequip.ogg"))
			await get_tree().process_frame
			grab_item_focus()


func _on_button_reference_received(reference) -> void:
	if item_spirit_tabs.current_tab == 0:
		side_load_item_data(reference)
	if item_spirit_tabs.current_tab == 1:
		side_load_spirit_data(reference)


func party_size() -> int:
	return DAT.get_data("party", [0]).size()


# return either a party memeber or the party array
func party(index: int = -1):
	if index > -1 and index < party_size():
		return DAT.get_character(DAT.get_data("party", ["greg"])[index])
	else:
		return (DAT.get_data("party", ["greg"]))


func showme():
	show()
	SND.menusound()
	if DAT.seconds - DAT.last_save_second > TIME_AFTER_WARN_SAVE:
		save_warning_label.show()
		save_warning_label.modulate.a = 1.0
		var tw := create_tween()
		tw.tween_property(save_warning_label, "modulate:a", 0.0, 2.0)
		tw.tween_callback(save_warning_label.hide)


func hideme():
	hide()
	doing = Doings.INNER
	doing = Doings.PARTY
	using_menu.hide()
	grab_item_focus()
