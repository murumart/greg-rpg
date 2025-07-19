extends OverworldCharacter

const TQKEY := &"nat_toothquest_on"

var difficulty := 0.0

@onready var random_battle_component: RandomBattleComponent = $RandomBattleComponent
@onready var tooth_reward: Reward = $RandomBattleComponent.default_battle.rewards.rewards[0]

func _ready() -> void:
	super._ready()
	if DAT.get_data(TQKEY, false) and ResMan.get_character("greg").level >= 20:
		tooth_reward.chance = 1
	random_battle_component.set_level(difficulty)
	battle_info = random_battle_component.get_battle()


func interacted() -> void:
	if DAT.player_capturers.size() > 0:
		return
	interactions += 1
	inspected.emit()
	LTS.enter_battle(battle_info, {"wait_time": 2.0, "play_fanfare": false, "kill_music": false})
	set_physics_process(false)
