extends OverworldCharacter

const B := "broken_fisherman"
const S := "sopping"
const F := "fish"
const N := "not_fish"

static var broken_fishermen_fought_changed := false


func _ready() -> void:
	super._ready()
	battle_info = BattleInfo.new().set_background("lakeside").set_music("lake_battle").\
	set_enemies(gen_enemies()).set_rewards(preload("res://resources/rewards/res_lakeside_reward.tres")).set_death_reason("lakeside")


func interacted() -> void:
	if not broken_fishermen_fought_changed:
		DAT.incri("broken_fishermen_fought", 1)
		broken_fishermen_fought_changed = true
	super()


func gen_enemies() -> Array[String]:
	var enemies: Array[String] = []
	var level := DAT.get_character("greg").level
	if level < 25:
		enemies.append(B)
		if randf() <= 0.5: enemies.append(S)
		if randf() <= 0.05: enemies.append(F)
		if randf() <= 0.05: enemies.append(B)
	else:
		enemies.append(B)
		if randf() <= 0.75: enemies.append(S)
		if randf() <= 0.3: enemies.append(N)
		if randf() <= 0.2: enemies.append(S)
		if randf() <= 0.2: enemies.append(F)
		if randf() <= 0.05: enemies.append(B)
	if enemies.size() > 4:
		enemies.resize(4)
	enemies.shuffle()
	return enemies
