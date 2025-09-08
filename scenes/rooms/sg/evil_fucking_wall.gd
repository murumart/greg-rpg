extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var greg: PlayerOverworld
@export var path_follower_parent: PathFollow2D

var active := false


func _ready() -> void:
	active = false
	body_entered.connect(func(body: PlayerOverworld) -> void:
		if not active or "cutscene" in DAT.player_capturers:
			return
		LTS.to_game_over_screen()
	)


func _physics_process(delta: float) -> void:
	if not active:
		return
	var speed := 0.0
	speed = clampf(remap(global_position.distance_squared_to(greg.global_position), 0.0, 25600, 5.0, 55.0), 5.0, 55.0)
	path_follower_parent.progress += speed * delta


func activate() -> void:
	show()
	active = true
