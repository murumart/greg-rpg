extends Node2D
class_name BattleActor

const WAIT_AFTER_ATTACK := 2.0
const WAIT_AFTER_SPIRIT := 2.0
const WAIT_AFTER_ITEM := 2.0

signal message(msg: String)
signal act_requested(by_whom: BattleActor)
signal act_finished(by_whom: BattleActor)
signal player_input_requested(by_whom: BattleActor)

enum States {IDLE = -1, COOLDOWN, ACTING, DEAD}
var state : States = States.IDLE : set = set_state

@export var character_id : int = -1
var actor_name : StringName
@onready var character : Character
@export var weapon : Item
@export var armour : Item
var status_effects : Dictionary = {}

var reference_to_team_array := []
var reference_to_opposing_array := []
var reference_to_actor_array := []

var player_controlled := false

var wait := 1.0


func _ready() -> void:
	character = load_character(character_id)
	actor_name = character.name


func _physics_process(delta: float) -> void:
	match state:
		States.IDLE:
			pass
		States.COOLDOWN:
			wait = maxf(wait - sqrt(delta * get_speed() * 0.1), 0.0)
			if wait == 0.0:
				act_requested.emit(self)
				set_state(States.ACTING)
		States.ACTING:
			pass
		States.DEAD:
			pass


func act() -> void:
	set_state(States.ACTING)
	wait = 1.0
	print(actor_name, " is acting!")
	if player_controlled:
		player_input_requested.emit(self)
		return


func set_state(to: States) -> void:
	if not state == States.DEAD:
		state = to


func heal(amount: float) -> void:
	character.health = minf(character.health + amount, character.max_health)


func hurt(amount: float) -> void:
	character.health = maxf(character.health - absf(amount), 0.0)
	if character.health <= 0.0:
		state = States.DEAD


func get_attack() -> float:
	var x := 0.0
	x += character.attack
	if armour and armour.payload:
		x += armour.payload.attack_increase
	if weapon and weapon.payload:
		x += weapon.payload.attack_increase
	if status_effects.get("attack", {}):
		x += status_effects.get("attack").get("strength")
	return maxf(x, 1)


func get_defense() -> float:
	var x := 0.0
	x += character.defense
	if armour and armour.payload:
		x += armour.payload.defense_increase
	if weapon and weapon.payload:
		x += weapon.payload.defense_increase
	if status_effects.get("defense", {}):
		x += status_effects.get("defense").get("strength")
	return maxf(x, 1)


func get_speed() -> float:
	var x := 0.0
	x += character.speed
	if armour and armour.payload:
		x += armour.payload.speed_increase
	if weapon and weapon.payload:
		x += weapon.payload.speed_increase
	if status_effects.get("speed", {}):
		x += status_effects.get("speed").get("strength")
	return maxf(x, 1)


static func calc_attack_damage(atk: float, random := true) -> float:
	var x := 0.0
	x += atk
	if random: x += randf() * 2
	var y := roundf(Math.method_29193(x))
	return y


func account_defense(x: float) -> float:
	var def := get_defense()
	var result := maxf(abs(x) - sqrt(def), 1)
	return roundf(result)


func attack(subject: BattleActor) -> void:
	var pld := payload().set_health(-BattleActor.calc_attack_damage(get_attack()))
	subject.handle_payload(pld)
	SOL.vfx_dustpuff(subject.global_position)
	SND.play_sound(preload("res://sounds/snd_attack_blunt.ogg"))
	await get_tree().create_timer(WAIT_AFTER_ATTACK).timeout
	turn_finished()


func use_item(id: int, subject: BattleActor) -> void:
	var item : Item = DAT.get_item(id)
	subject.handle_payload(item.payload)
	if item.use != Item.Uses.NONE:
		character.inventory.erase(id)
	await get_tree().create_timer(WAIT_AFTER_ITEM).timeout
	turn_finished()


func handle_payload(pld: BattlePayload) -> void:
	await get_tree().process_frame
	print(actor_name, ": payload received from %s! " % pld.sender)
	
	var health_change := 0.0
	health_change += pld.health
	health_change += pld.health_percent * character.health
	health_change += pld.max_health_percent * character.max_health
	if health_change:
		if health_change > 0:
			heal(health_change)
		else:
			health_change = lerpf(account_defense(health_change), health_change, pld.pierce_defense)
			hurt(health_change)
	
	character.magic += pld.magic + (pld.magic_percent * character.magic) + (pld.max_magic_percent * character.max_magic)
	
	introduce_status_effect("attack", pld.attack_increase, pld.attack_increase_time)
	introduce_status_effect("defense", pld.defense_increase, pld.defense_increase_time)
	introduce_status_effect("speed", pld.speed_increase, pld.speed_increase_time)
	



func status_effect_update() -> void:
	for e in status_effects.keys():
		var effect : Dictionary = status_effects[e]
		effect["duration"] = effect.get("duration", 1) - 1
		if effect.get("duration", 1) < 1:
			status_effects[e] = {}


func introduce_status_effect(nomen: String, strength: float, duration: int) -> void:
	status_effects[nomen] = {
		"strength": strength,
		"duration": duration
	}


func turn_finished() -> void:
	act_finished.emit(self)
	status_effect_update()


func load_character(id: int) -> Character:
	return DAT.get_character(id).duplicate(false) # will crash if using deep copy here


func offload_character() -> void:
	DAT.character_list[character_id] = character


func payload() -> BattlePayload:
	return BattlePayload.new().set_sender(self)

