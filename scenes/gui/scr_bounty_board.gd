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

var _quests: Array[Quest]


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
		rb.return_reference.connect(_quest_selected)
	(bounty_list.get_child(0) as Control).grab_focus.call_deferred()
	claim_button.hide()


func _quest_selected(q: Quest) -> void:
	description_text.text = q.description
	progress_bar.value = float(q.completion_numerator) / float(q.completion_denominator)
	claim_button.visible = is_instance_valid(q.reward)
	claim_button.disabled = q.completion_numerator < q.completion_denominator


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
