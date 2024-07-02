extends OverworldCharacter

@onready var sprite := $CatSprite
@export var friendly := false


func _ready() -> void:
	super._ready()
	if friendly:
		return


func _physics_process(delta: float) -> void:
	super(delta)

	if velocity.length_squared() > 1:
		sprite.play("running")
		sprite.rotation = velocity.angle() - PI * 0.5
		sprite.position.y = 0
	else:
		sprite.play("idle")
		sprite.rotation = 0
		sprite.position.y = -7

