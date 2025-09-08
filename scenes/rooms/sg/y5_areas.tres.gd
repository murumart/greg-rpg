extends Node2D

@onready var cat_2 := $Cats/SgCatOwl
@onready var trash_bin: TrashBin = $TrashBin

@export var cat_battle: BattleInfo


func _ready() -> void:
	if not is_instance_valid(cat_2):
		return
	if not trash_bin.full:
		cat_2.convo_progress = 0
		cat_2.default_lines.assign(["sg_trashbin_opened"])
	trash_bin.opened.connect(func() -> void:
		cat_2.convo_progress = 0
		cat_2.default_lines.assign(["sg_trashbin_opened"])
	)
	cat_2.inspected.connect(func() -> void:
		if DAT.get_data("heard_trashbin_importance", false) and not trash_bin.full:
			await SOL.dialogue_closed
			DAT.capture_player("cutscene")
			await cat_2.scary()
			DAT.free_player("cutscene")
			cat_2.battle_info = cat_battle
			cat_2.enter_battle()
	)
