extends OverworldCharacter

const SP := "stray_pet"
const WL := "wild_lizard"
const M := "mole"
const RB := "rainbird"

var enmis : Array[String] = []


func _ready() -> void:
	super._ready()
	battle_info = get_info()


func get_info() -> BattleInfo:
	var inf := BattleInfo.new()
	var level := DAT.get_character("greg").level
	
	if Math.inrange(level, 0, 10):
		enmis.append(SP)
		c(0.25, M)
		c(0.25, SP)
		c(0.1, RB)
	elif Math.inrange(level, 10, 16):
		enmis.append(SP)
		c(0.33, M)
		c(0.25, SP)
		c(0.25, RB)
	elif Math.inrange(level, 16, 24):
		enmis.append(SP)
		c(0.5, M)
		c(0.25, SP)
		c(0.25, RB)
		c(0.15, M)
		c(0.07, WL)
	elif Math.inrange(level, 24, 32):
		enmis.append(SP)
		enmis.append(M)
		c(0.5, M)
		c(0.5, SP)
		c(0.15, WL)
		c(0.25, RB)
	elif Math.inrange(level, 33, 99):
		enmis.append(WL)
		enmis.append(RB)
		enmis.append(SP)
		enmis.append(M)
	
	enmis.shuffle()
	if enmis.size() > 4:
		enmis.resize(4)
	
	inf.set_background("town").set_music("foreign_fauna")
	inf.set_enemies(enmis)
	inf.set_rewards(preload("res://resources/rewards/res_animal_fight_rewards.tres"))
	
	return inf


func c(chance: float, en: String) -> void:
	if randf() <= chance: enmis.append(en)
