extends OverworldCharacter

@export var wild_lizard_probability : Curve
@export var freebird_probability : Curve
@export var fox_probability : Curve
@export var worm_probability : Curve

@onready var probabilities := {
	&"wild_lizard": wild_lizard_probability,
	&"freebird": freebird_probability,
	&"fox": fox_probability,
	&"worm": worm_probability
	
}

var difficulty := 0.0


func _ready() -> void:
	super._ready()
	battle_info = BattleInfo.new()
	battle_info.stop_music_before_end = false
	battle_info.victory_music = false
	battle_info.set_enemies(gen_enemies()).set_music("lion").set_background("forest")
	battle_info.set_rewards(preload("res://resources/rewards/res_thug_reward.tres"
	)).set_start_text(["ravenous.", "hungry.", "wild.", "rampaging.",
	"found you.", "life."].pick_random())


func interacted() -> void:
	if DAT.player_capturers.size() > 0: return
	interactions += 1
	inspected.emit()
	LTS.enter_battle(battle_info, {"wait_time": 2.0, "play_fanfare": false, "kill_music": false})
	set_physics_process(false)


func gen_enemies() -> Array[String]:
	var enemies : Array[String] = []
	for i in ceili(difficulty / 10.0) + 1:
		for k in probabilities.keys():
			var curve := probabilities[k] as Curve
			if curve.sample(difficulty) >= randf():
				enemies.append(k)
	enemies.shuffle()
	if enemies.size() > 4:
		enemies.resize(4)
	return enemies

