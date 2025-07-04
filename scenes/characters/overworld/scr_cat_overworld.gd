extends OverworldCharacter

@onready var sprite := $CatSprite
@export var friendly := false
@onready var meow: AudioStreamPlayer = $Meow


func _ready() -> void:
	super._ready()
	if friendly:
		battle_info = null
		interact_on_touch = false


func interacted() -> void:
	super()
	meow.play()


func _physics_process(delta: float) -> void:
	super(delta)

	if velocity.length_squared() > 1:
		sprite.play("running")
		sprite.rotation = velocity.angle() - PI * 0.5
	else:
		sprite.play("idle")
		sprite.rotation = 0
