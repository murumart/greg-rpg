extends OverworldCharacter

@onready var sprite := $CatSprite
@export var friendly := false


func _ready() -> void:
	super._ready()
	if friendly: return
	var enemis: Array[String] = []
	enemis.append_array(Math.mult_arr(["cat"], randi_range(1, 3)))
	battle_info = BattleInfo.new().set_enemies(enemis).\
	set_background("greghouse").set_music("catfight").set_start_text("ravenous beasts!").\
	set_death_reason("cats")


func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if velocity.length_squared() > 1:
		sprite.play("running")
		sprite.rotation = velocity.angle() - PI/2.0
		sprite.position.y = 0
	else:
		sprite.play("idle")
		sprite.rotation = 0
		sprite.position.y = -7

