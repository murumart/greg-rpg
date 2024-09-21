extends Control

signal finished

@onready var trashes := $CenterContainer/Panel/HBoxContainer.get_children()
var _selection := -1
var _accepts_input = false


func reset() -> void:
	_selection = -1
	_accepts_input = false


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
		for i in trashes.size():
			var trash: Control = trashes[i]
			if trash.scale != Vector2.ONE and _selection != i:
				var tw := create_tween().set_trans(Tween.TRANS_BOUNCE)
				tw.tween_property(trash, "scale", Vector2.ONE, 0.2)
		var tw := trashes[_selection].create_tween().set_trans(Tween.TRANS_SPRING)
		tw.tween_property(trashes[_selection], "scale", Vector2(1.4, 1.4), 0.2)

	if event.is_action_pressed("ui_accept"):
		if _selection < 0:
			return
		var trash: Control = trashes[_selection]
		var animator: AnimationPlayer = trash.get_node("AnimationPlayer")
		animator.play("open")
		_accepts_input = false
		await animator.animation_finished
		# TODO: display other options

		if trashes.is_empty():
			finished.emit()
			return

		var prompt := SOL.display_user_prompt(Rect2(40, 74, 82, 40),
				{
					UserPrompt.TITLE: "do you want to try again?",
					UserPrompt.TYPE: UserPrompt.TYPE_BUTTONS,
					UserPrompt.BUTTON_NAMES: ["yes", "no"] if trashes.size() > 1 else ["no"],
				})
		prompt.submitted.connect(func(a: String) -> void:
			if a == "no":
				finished.emit()
				return
			remove_bin(_selection)
			reset()
			_accepts_input = true
		)
		finished.emit()


func remove_bin(index: int) -> void:
	var trash := trashes[index]
	trashes.remove_at(index)
	trash.queue_free()
