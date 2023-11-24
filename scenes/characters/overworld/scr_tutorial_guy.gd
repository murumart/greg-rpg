extends OverworldCharacter

enum TutorialType {
		OPEN_INVENTORY,
		EQUIPPING_ITEMS,
		GREENHOUSES,
}

@onready var visibility_notif: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@export var tutorial_type: TutorialType


func _ready() -> void:
	super()
	inspected.connect(_talked)
	check_deserved_existence()
	visibility_notif.screen_entered.connect(check_deserved_existence)
	visibility_notif.screen_exited.connect(check_deserved_existence)


func check_deserved_existence() -> void:
	match tutorial_type:
		TutorialType.OPEN_INVENTORY:
			if DAT.get_data("has_opened_inventory", false):
				queue_free()
				return
			default_lines.append("tutguy_open_inventory")
		TutorialType.EQUIPPING_ITEMS:
			if DAT.get_data("equipped_item", false):
				queue_free()
				return
		TutorialType.GREENHOUSES:
			if DAT.get_data("greenhouses_eaten", 0) or DAT.get_data("greenhouses_slept", 0):
				queue_free()
				return


func _talked() -> void:
	default_lines.clear()
	if not DAT.get_data("talked_to_tutguy", false):
		SOL.dialogue("tutguy_intro")
	if tutorial_type == TutorialType.OPEN_INVENTORY:
		SOL.dialogue("tutguy_open_inventory")
	elif tutorial_type == TutorialType.EQUIPPING_ITEMS:
		SOL.dialogue("tutguy_equip_items")
	elif tutorial_type == TutorialType.GREENHOUSES:
		SOL.dialogue("tutguy_greenhouses")
	SOL.dialogue("tutguy_bye")


func _exit_tree() -> void:
	print("bye")
