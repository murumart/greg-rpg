extends Node

const WAIT_TIME := 1.0
const DEFA_DAMAGE := 16.0

@export var greg_overworld: PlayerOverworld
@export var hurt_area: Area2D
@export var info: PartyMemberInfoPanel

var _timer: Timer
var _greg: BattleActor
var _deaths := 0


func _ready() -> void:
	_deaths = DAT.get_data("deaths", []).count(int(DAT.DeathReasons.X))
	_timer = Timer.new()
	_timer.wait_time = WAIT_TIME
	_timer.one_shot = true
	add_child(_timer)
	_greg = BattleActor.new()
	_greg.character = ResMan.get_character("greg")
	greg_overworld.add_child(_greg)
	hurt_area.area_entered.connect(_on_hit)
	info.get_parent().remove_child(info)
	var tw := create_tween().set_loops(0)
	tw.tween_interval(1)
	tw.tween_callback(info.update.bind(_greg))
	SOL.add_ui_child(info)
	if DAT.get_data("x_chase_done", false):
		info.queue_free()
	info.update(_greg)


func _on_hit(area: Area2D) -> void:
	if "cutscene" in DAT.player_capturers:
		return
	var dmg := DEFA_DAMAGE
	if "damage" in area:
		dmg = area.damage
	if area.has_meta("damage"):
		dmg = area.get_meta("damage", DEFA_DAMAGE)
	dmg = maxi(dmg - _deaths * 4, 1)
	dmg = dmg * ((WAIT_TIME - _timer.time_left) / WAIT_TIME)**2
	if greg_overworld.menu.visible:
		dmg *= 4.0 / _deaths
	_greg.hurt(dmg, Genders.VAST)
	if _greg.character.health_perc() <= 0:
		hurt_area.area_entered.disconnect(_on_hit)
		_die()
	_timer.start(WAIT_TIME)
	info.update(_greg)


func _die() -> void:
	greg_overworld.rotate(PI * 0.5)
	LTS.to_game_over_screen()
