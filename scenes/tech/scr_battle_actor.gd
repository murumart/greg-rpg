extends Node2D
class_name BattleActor

signal message_sent(message: String)

enum States {IDLE = -1, COOLDOWN, ACTING, DEAD}
var state : States = States.IDLE : set = set_state

@export var character_id : int = -1
@onready var character : Character

var wait := 1.0


func _ready() -> void:
	character = load_character(character_id)


func _physics_process(delta: float) -> void:
	match state:
		States.IDLE:
			pass
		States.COOLDOWN:
			pass
		States.ACTING:
			pass
		States.DEAD:
			pass


func set_state(to: States) -> void:
	state = to


func heal(amount: float) -> void:
	character.health = minf(character.health + amount, character.max_health)


func hurt(amount: float) -> void:
	character.health = maxf(character.health - amount, 0.0)
	if character.health <= 0.0:
		state = States.DEAD


func attack(node: BattleActor) -> void:
	var payload := payload().set_health(-10.0)
	node.handle_payload(payload)


func handle_payload(pld: BattlePayload) -> void:
	print("payload received! ", pld.get_script().get_script_property_list())


func load_character(id: int) -> Character:
	return DAT.get_character(id).duplicate(false) # will crash if using deep copy here


func offload_character() -> void:
	DAT.character_list[character_id] = character


func payload() -> BattlePayload:
	return BattlePayload.new().set_sender(self)
