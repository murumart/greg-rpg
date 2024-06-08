extends BattleEnemy

const PIZZ_TIME := [
	"time until pizz delivery: %.1f sec",
	"eta pizz: %.1f sec",
	"pizz is here in: %.1f sec",
	"pizz imminent: %.1f sec",
]

var pizz_message := "%.1f"

@onready var time_for_pizz: Control = $TimeForPizz
@onready var time_limit_label: Label = $TimeForPizz/TimeLimitLabel
@onready var canvas_group: Node2D = $Node/CanvasGroup

var time_left: float = 25.0


func _ready() -> void:
	super()
	remove_child(time_for_pizz)
	SOL.add_ui_child(time_for_pizz)
	pizz_message = Math.determ_pick_random(PIZZ_TIME, rng)


func _process(delta: float) -> void:
	super(delta)
	if state == States.COOLDOWN or state == States.ACTING:
		time_left -= delta
	time_limit_label.text = str(pizz_message % time_left)
	time_limit_label.modulate.g = minf(time_left * 0.1, 1.0)
	time_limit_label.modulate.b = minf(time_left * 0.1, 1.0)
	canvas_group.material.set("shader_parameter/iridescence_reducer", character.health_perc() * 0.85)


func _pizz_arrival_animation() -> void:
	auto_ai = false
	animate("RESET")
	print("ifaoifnasofnasofsanfo")
