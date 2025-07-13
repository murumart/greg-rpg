extends Node2D

const BountyBoard = preload("res://scenes/gui/scr_bounty_board.gd")

const SCN_BOUNTY_BOARD = preload("res://scenes/gui/scn_bounty_board.tscn")
const SCN_REFERENCE_BUTTON = preload("res://scenes/tech/scn_reference_button.tscn")

signal close_requested

@onready var bounty_list: VBoxContainer = %BountyList
@onready var description_text: RichTextLabel = %DescriptionText
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var claim_button: Button = %ClaimButton
@onready var title_label: Label = %TitleLabel
@onready var description_autoscroll: AutoscrollComponent = %DescriptionAutoscroll

var _quests: Array[Quest]
var _current_quest: Quest


static func make(quests: Array[Quest]) -> BountyBoard:
	var scn: BountyBoard = SCN_BOUNTY_BOARD.instantiate()
	scn._quests = quests
	return scn


func _ready() -> void:
	if _quests.is_empty():
		return
	for q in _quests:
		var rb := SCN_REFERENCE_BUTTON.instantiate()
		bounty_list.add_child(rb)
		rb.text = q.name
		rb.reference = q
		rb.selected_return_reference.connect(_quest_selected)
	_refocus()
	claim_button.hide()


func _refocus() -> void:
	(bounty_list.get_child(0) as Control).grab_focus.call_deferred()


func _quest_selected(q: Quest) -> void:
	description_text.text = q.description
	description_autoscroll.reset()
	progress_bar.value = float(q.completion_numerator) / float(q.completion_denominator)
	claim_button.visible = is_instance_valid(q.reward)
	claim_button.disabled = q.completion_numerator < q.completion_denominator
	_current_quest = q
	Math.remove_connections(claim_button.pressed)
	claim_button.pressed.connect(_claim_pressed.bind(q))


func _claim_pressed(q: Quest) -> void:
	if not is_instance_valid(q.reward):
		return
	if q.completion_numerator < q.completion_denominator:
		return
	q.reward.grant(true)
	await SOL.dialogue_closed
	_refocus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel"):
		close_requested.emit()
		hide()


class Quest:
	var name: String
	var description: String
	var completion_numerator: int
	var completion_denominator: int
	var reward: BattleRewards


	func _init(o: String, s: String, n: int, d: int, r: BattleRewards = null) -> void:
		name = o
		description = s
		completion_numerator = n
		completion_denominator = d
		reward = r
