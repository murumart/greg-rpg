extends Node2D

const QuestBoard = preload("res://scenes/gui/scr_bounty_board.gd")

const SCN_BOUNTY_BOARD = preload("res://scenes/gui/scn_bounty_board.tscn")
const SCN_REFERENCE_BUTTON = preload("res://scenes/tech/scn_reference_button.tscn")
const SCN_QUEST_SEPARATOR = preload("res://scenes/gui/scn_quest_separator.tscn")

signal close_requested

@onready var quest_list: VBoxContainer = %QuestList
@onready var description_text: RichTextLabel = %DescriptionText
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var claim_button: Button = %ClaimButton
@onready var title_label: Label = %TitleLabel
@onready var description_autoscroll: AutoscrollComponent = %DescriptionAutoscroll

var _quests: Array[QuestListElement]
var _current_quest: Quest


static func make() -> QuestBoard:
	var scn: QuestBoard = SCN_BOUNTY_BOARD.instantiate()
	return scn


func fill(quests: Array[QuestListElement]) -> QuestBoard:
	_quests = quests
	_buttons()
	return self


func _buttons() -> void:
	for q in quest_list.get_children():
		q.free()
	if _quests.is_empty():
		return
	for q in _quests:
		if q is Quest:
			var rb := SCN_REFERENCE_BUTTON.instantiate()
			quest_list.add_child(rb)
			rb.text = q.name
			rb.reference = q
			rb.selected_return_reference.connect(_quest_selected)
			rb.pressed.connect(_quest_button_pressed)
		else:
			var l := SCN_QUEST_SEPARATOR.instantiate()
			l.get_child(0).text = q.name
			quest_list.add_child(l)
	_refocus()


func _refocus() -> void:
	for c: Control in quest_list.get_children():
		if c is Button:
			c.grab_focus()
			return


func _quest_selected(q: Quest) -> void:
	description_text.text = q.description
	description_autoscroll.reset()
	Math.remove_connections(claim_button.pressed)
	if q.ongoiong:
		claim_button.text = "claim reward"
		progress_bar.show()
		progress_bar.value = float(q.completion_numerator) / float(q.completion_denominator)
		claim_button.visible = is_instance_valid(q.reward)
		claim_button.disabled = q.completion_numerator < q.completion_denominator
		claim_button.pressed.connect(_claim_pressed.bind(q))
	else:
		claim_button.text = "start quest"
		progress_bar.hide()
		claim_button.show()
		claim_button.disabled = false
		claim_button.pressed.connect(_quest_started.bind(q))
	_current_quest = q


func _claim_pressed(q: Quest) -> void:
	if not is_instance_valid(q.reward):
		return
	if q.completion_numerator < q.completion_denominator:
		return
	q.reward.grant(true)
	await SOL.dialogue_closed
	_refocus()


func _quest_started(q: Quest) -> void:
	q.ongoiong = true
	fill(_quests)


func _quest_button_pressed() -> void:
	if claim_button.disabled:
		return
	claim_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		get_window().set_input_as_handled()
		if claim_button.has_focus():
			_refocus()
			return
		close_requested.emit()
		hide()


class QuestListElement:
	var name: String


	func _init(n: String) -> void:
		name = n


class Quest extends QuestListElement:
	var description: String
	var completion_numerator: int
	var completion_denominator: int
	var reward: BattleRewards
	var ongoiong: bool


	func _init(
		nam: String,
		desc: String,
		num: int,
		den: int,
		r: BattleRewards = null,
		ong := false
	) -> void:
		super(nam)
		description = desc
		completion_numerator = num
		completion_denominator = den
		reward = r
		ongoiong = ong
