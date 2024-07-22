extends BattleEnemy

const ATTACK := preload("res://sprites/characters/battle/grandma/spr_attack.png")

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super._ready()


func act() -> void:
	var greg: BattleActor = reference_to_opposing_array[0]
	message.emit("grandma attacked greg!")
	sprite.texture = ATTACK
	for i in 400:
		greg.hurt(1, Genders.VAST)
		await get_tree().process_frame
		sprite.flip_h = not sprite.flip_h
		if greg.character.health_perc() < 0.1:
			break
	SND.play_song("")
	DAT.set_data("fought_grandma", true)
	DAT.set_data("intro_progress", 2)
	LTS.gate_id = LTS.GATE_EXIT_BATTLE
	await get_tree().create_timer(0.75).timeout
	LTS.level_transition(LTS.ROOM_SCENE_PATH % "grandma_house_inside")


func _item_diploma_used_on() -> void:
	SOL.dialogue("grandma_diploma_use")
