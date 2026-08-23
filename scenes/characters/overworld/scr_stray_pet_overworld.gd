extends OverworldCharacter

const TQKEY := &"nat_toothquest_on"

@onready var tooth_reward: Reward = $RandomBattleComponent.default_battle.rewards.rewards[0]


func interacted() -> void:
	if DAT.get_data(TQKEY, false) and ResMan.get_character("greg").level >= 20:
		tooth_reward.chance = 1
	super()
