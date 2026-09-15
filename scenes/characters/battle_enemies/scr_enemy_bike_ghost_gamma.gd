extends BattleEnemy

var _noticed_immunce := false
var _warned_firegrave := false
var _using_firegrave := false


func _ready() -> void:
	super()
	SOL.dialogue("bike_gamma_battle_1")


func die() -> void:
	if _using_firegrave:
		super()
		return
	SOL.dialogue("bike_gamma_battle_die")
	ignore_my_finishes = true
	auto_ai = false
	await SOL.dialogue_closed
	await _get_firegraved()
	super()


func act() -> void:
	var tgt := pick_target()
	if tgt.is_immune_to("fire"):
		default_intent = Intents.ATTACK
		if not _noticed_immunce:
			_noticed_immunce = true
			SOL.dialogue("bike_gamma_battle_immune")
			await SOL.dialogue_closed
		Math.ensure_member(hurting_spirits, "ghostpunches")
		debuffing_spirits.erase("flame_ouch_better")
		debuffing_spirits.erase("flare")
	else:
		default_intent = Intents.DEBUFF
		hurting_spirits.erase("ghostpunches")
		Math.ensure_member(debuffing_spirits, "flame_ouch_better")
		Math.ensure_member(debuffing_spirits, "flare")
	if turn > 3 and character.health_perc() < 0.2 and not _warned_firegrave:
		_warned_firegrave = true
		ignore_my_finishes = true
		SOL.dialogue("bike_gamma_battle_2")
		await SOL.dialogue_closed
		await _get_firegraved()
		await Math.timer(2.0)
		if tgt.character.health_perc() > 0:
			SOL.dialogue("bike_gamma_battle_3")
			await SOL.dialogue_closed
			ignore_my_finishes = false
			flee()
		return
	super()


func _get_firegraved() -> void:
	_using_firegrave = true
	SND.play_song("", 99)
	var tgt := pick_target()
	for i in 30:
		use_spirit("flame_ouch_better", tgt)
		await Math.timer(0.1)
	_using_firegrave = false
	await Math.timer(1.0)
