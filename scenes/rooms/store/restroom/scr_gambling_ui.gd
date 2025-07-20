extends Control

const Trash := preload("res://scenes/rooms/store/restroom/scr_trash_display.gd")

signal finished

const ITEMS_1 := [&"gummy_worm", &"bread", &"plaster",
	&"cigarette", &"cough_syrup", &"pills", &"cracker_fire",
	&"coin_lure", &"egg", &"plaster", &"gummy_worm", &"gummy_fish",
	&"salt", &"milk", &"bread"]

const ITEMS_2 := [&"gummy_fish", &"mueslibar", &"muesli", &"tape",
	&"sugar_lemon", &"soda", &"pocket_candy", &"medkit", &"magnet",
	&"free_hugs_coupon", &"eggshell", &"combo_lure", &"berries"]

@onready var hand: TextureRect = $Hand

var trashes: Array[Trash]

var _selection := -1
var _accepts_input = false
var _items_chosen := []
var _items: Array[StringName]
var _tries := 0


func _ready() -> void:
	hide()
	trashes.assign($CenterContainer/Panel/HBoxContainer.get_children())


func reset() -> void:
	_selection = -1
	_accepts_input = false
	_prepare_trash_selection()


func display() -> void:
	_accepts_input = true
	show()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _accepts_input:
		return

	var movex := Input.get_axis("ui_left", "ui_right")
	var oldselect := _selection
	if movex:
		_selection = wrapi(_selection + int(movex), 0, trashes.size())

	if oldselect != _selection:
		SND.menusound(1.1)
		var select := trashes[_selection]
		var tw := select.create_tween().set_trans(Tween.TRANS_SPRING)
		tw.parallel().tween_property(hand, ^"self_modulate:a", 1.0, 0.1)
		tw.tween_property(hand, ^"global_position:x", select.global_position.x + select.size.x * 0.5 - hand.size.x * 0.5, 0.1)
		get_window().set_input_as_handled()

	if event.is_action_pressed("ui_accept"):
		_trash_selected()
		get_window().set_input_as_handled()


func _prepare_trash_selection() -> void:
	for t in trashes:
		t.animator.play("RESET")


func _trash_selected() -> void:
	_tries += 1
	_choose_items()
	if _selection < 0:
		return
	var trash: Control = trashes[_selection]
	var tw := trash.create_tween().set_trans(Tween.TRANS_SPRING)
	tw.tween_property(hand, ^"self_modulate:a", 0.0, 0.2)
	var item := ResMan.get_item(_items[_selection])
	trash.item_texture.texture = item.texture
	trash.animator.play("open")
	_accepts_input = false
	_items_chosen.append(_items[_selection])
	await trash.animator.animation_finished
	trash.animator.play("item_show")
	# TODO: display other options
	for t in trashes.size():
		if t == _selection:
			continue
		trashes[t].item_texture.texture = ResMan.get_item(_items[t]).texture
		trashes[t].animator.play("open_small")
		trashes[t].animator.queue("item_show")
		await Math.timer(0.1)

	if trashes.size() <= 1:
		_done()
		return

	var new_cost := (_tries + 1) * 65
	var aval_choices := [&"no"]
	if DAT.get_data("silver", 0) >= new_cost:
		aval_choices.append(&"yes")
	var a := await DialogueBuilder.new().add_line(DialogueLine.mk("try again? (%s silver)" % new_cost).schoices(aval_choices)).speak_choice()
	if a == "no":
		_done()
		return
	DAT.incri("silver", -new_cost)
	remove_bin(_selection)
	_items.remove_at(_selection)
	_items.shuffle()
	reset()
	_prepare_trash_selection()
	_accepts_input = true


func _choose_items() -> void:
	if not _items_chosen.is_empty():
		return
	for i in trashes.size():
		if i == _selection:
			_items.append(ITEMS_1.pick_random())
		else:
			_items.append(ITEMS_2.pick_random())


func _done() -> void:
	for it in _items_chosen:
		DAT.grant_item(it)
	finished.emit()


func remove_bin(index: int) -> void:
	var trash := trashes[index]
	trashes.remove_at(index)
	trash.queue_free()
