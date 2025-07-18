extends BattleEnemy


func _ready() -> void:
	super()
	if not DAT.get_data("scooterer_introed", false):
		DAT.set_data("scooterer_introed", true)
		SOL.dialogue("mayor_scooter_intro")


func act() -> void:
	if character.magic < character.max_magic:
		use_spirit("scooter_rev", self)
		return
	else:
		super()
		return
	super()
