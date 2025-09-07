extends Node

const WAIT_TIME := 1.0

@export var greg_overworld: PlayerOverworld
@export var hurt_area: Area2D

var _timer: Timer
var _greg: BattleActor


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = WAIT_TIME
	_timer.one_shot = true
	add_child(_timer)
	_greg = BattleActor.new()
	_greg.character = ResMan.get_character("greg")
	greg_overworld.add_child(_greg)
	hurt_area.area_entered.connect(_on_hit)


func _on_hit(area: Area2D) -> void:
	var dmg := 20.0
	if "damage" in area:
		dmg = area.damage
	if area.has_meta("damage"):
		dmg = area.get_meta("damage", 20.0)
	dmg = dmg * ((WAIT_TIME - _timer.time_left) / WAIT_TIME)**2
	_greg.hurt(dmg, Genders.VAST)
	if _greg.character.health_perc() <= 0:
		hurt_area.area_entered.disconnect(_on_hit)
		_die()
	_timer.start(WAIT_TIME)


func _die() -> void:
	greg_overworld.rotate(PI * 0.5)
	LTS.to_game_over_screen()
