extends OverworldCharacter

@export var snakes_up := true

@onready var animator: AnimationPlayer = $Animator


func interacted() -> void:
	var to_wiggle := snakes_up and not (default_lines.is_empty() and battle_info == null)
	if to_wiggle:
		animator.play(&"emerge")
		animator.queue(&"wiggle")
	super()
	if SOL.dialogue_open and to_wiggle:
		SOL.dialogue_closed.connect(animator.play.bind(&"enhole"), CONNECT_ONE_SHOT)
