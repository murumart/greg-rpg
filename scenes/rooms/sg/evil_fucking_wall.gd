extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var greg: PlayerOverworld
@export var path_follower_parent: PathFollow2D

var active := false


func _ready() -> void:
	active = false
	body_entered.connect(func(body: PlayerOverworld) -> void:
		if not active:
			return
		LTS.to_game_over_screen()
	)


func _physics_process(delta: float) -> void:
	if not active:
		pass
	var speed := delta * 50
	#speed *= remap(global_position.distance_squared_to(greg.global_position), 0.0, 4096.0, 1.0, 0.5)
	path_follower_parent.progress += speed


func activate() -> void:
	animation_player.play(&"form")
	await animation_player.animation_finished
	active = true
