extends OverworldCharacter

const TQKEY := &"nat_toothquest_on"

@onready var tooth_reward: Reward = $RandomBattleComponent.default_battle.rewards.rewards[0]


func interacted() -> void:
	if DAT.get_data(TQKEY, false) and ResMan.get_character("greg").level >= 20:
		tooth_reward.chance = 1
	super()


func _car_collision_response(car: CarOverworld) -> void:
	SOL.vfx("dustpuff", global_position, {"parent": get_parent()})
	SOL.vfx("bangspark", global_position, {"parent": get_parent()})
	battle_info = null
	interact_on_touch = false
	SND.play_sound_2d(preload("res://sounds/attack_blunt.ogg"), global_position)
	var tw := create_tween()
	set_collision_mask_value(2, false)
	set_physics_process(false)
	var moveto := (car.global_position - car.target).normalized() * car.speed
	tw.tween_property(self, "global_position", moveto, 1.0)
	tw.tween_callback(queue_free)
