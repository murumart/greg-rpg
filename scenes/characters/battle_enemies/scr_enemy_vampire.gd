extends BattleEnemy

const BackgroundType := preload("res://scenes/battle_backgrounds/scr_bg_vampire.gd")
@onready var girl: Sprite2D = $Girl
@onready var vampire := $Vampire
@onready var limbs := [
	$Vampire/Core/LeftLeg, $Vampire/Core/RightLeg, $Vampire/Core/LeftArm,
	$Vampire/Core/LeftArm/LeftHand, $Vampire/Core/RightArm, $Vampire/Core/RightArm/RightHand,
	$Vampire/Core/Ribs, $Vampire/Core/Neck, $Vampire/Core/Neck/Head, $Vampire/Core/Neck/Head/Jaw
]
var background: BackgroundType

var progress := 0
var stolen_spirits: Array[String] = []
var has_stolen_spirits := false
var stole_spirit := false
var comments_made := 0


func _ready() -> void:
	super()
	if "background_container" in LTS.get_current_scene():
		background = LTS.get_current_scene().background_container.get_child(0) as BackgroundType
		background.mbc.new_beat.connect(_vampire_limb_flash)
	reference_to_opposing_array[0].act_requested.connect(_comments)
	SOL.dialogue("vampire_battle_start")
	DAT.set_data("vampire_end_cutscene", true)
	DAT.set_data("vampire_fought", true)


func _physics_process(delta: float) -> void:
	super(delta)
	if progress == 4:
		_vampire_limb_flash()


func act() -> void:
	if progress == 3:
		if not stole_spirit:
			var enemy_spirits := reference_to_opposing_array[0].character.spirits
			if enemy_spirits.size() > 0:
				has_stolen_spirits = true
				use_spirit("stealspirit", reference_to_opposing_array[0])
				var stolen: String = Math.determ_pick_random(enemy_spirits, rng)
				print("stolen: ", stolen)
				enemy_spirits.erase(stolen)
				if stolen == "hotel":
					stolen = "hotel_used_by_vampire"
				stolen_spirits.append(stolen)
				var stolen_spirit := DAT.get_spirit(stolen) as Spirit
				emit_message("vampire stole %s!" % stolen_spirit.name)
				stole_spirit = true
				SOL.set_deferred("dialogue_open", true)
				get_tree().create_timer(1.6).timeout.connect(func():
					if SOL.dialogue_exists("vampire_steal_%s" % stolen):
						SOL.dialogue("vampire_steal_%s" % stolen)
					else:
						SOL.dialogue("vampire_steal_default")
				)
				return
		if stolen_spirits.size() > 0:
			var stolen := stolen_spirits.pop_at(0) as StringName
			var stolen_spirit := DAT.get_spirit(stolen) as Spirit
			if stolen_spirit.use in Spirit.USES_POSITIVE:
				use_spirit(stolen, self)
				buffing_spirits.append(stolen)
			else:
				use_spirit(stolen, pick_target())
				hurting_spirits.append(stolen)
			stole_spirit = false
			return
	if not has_stolen_spirits and progress == 3:
		SOL.dialogue("vampire_no_spirits_to_steal")
		has_stolen_spirits = true
		await SOL.dialogue_closed
	super()


func hurt(amt: float, _g: int) -> void:
	amt = _progress_check(amt)
	if progress == 4 and SOL.dialogue_open:
		await SOL.dialogue_closed
	super(amt, _g)


func _item_salt_used_on() -> void:
	SOL.dialogue("vampire_battle_salt")


func _vampire_limb_flash() -> void:
	var limb := limbs.pick_random() as Node2D
	var tw := create_tween().set_trans(Tween.TRANS_SPRING)
	var channel := "rgbaaaaa"[randi() % 8]
	var to := maxf(randfn(0.1, 0.5), 0.1111111)
	if randf() <= 0.1:
		to += 2
	tw.tween_property(limb, "modulate:" + channel, to, 0.333 * randf())
	tw.tween_property(limb, "modulate:" + channel, 1, 0.333 * randf())


func _progress_check(damage: float) -> float:
	if (character.health - damage) / character.max_health < 0.7 and progress == 0:
		progress = 1
		hurting_spirits.append("powerpunch")
		SOL.dialogue("vampire_battle_70p")
		SOL.dialogue_closed.connect(func():
			# to pause the battle
			SOL.set_deferred("dialogue_open", true)
			var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
			tw.tween_interval(1.0)
			tw.tween_callback(
				SND.play_sound.bind({"pitch_scale": 0.89}).bind(
					preload("res://sounds/spirit/spirit_name_found.ogg")))
			tw.tween_callback(get_viewport().get_camera_2d().add_trauma.bind(1.0))
			tw.tween_property(vampire, "modulate:a", 2, 0.25)
			tw.tween_property(vampire, "modulate:a", 0.37, 0.55)
			tw.tween_interval(1.0)
			tw.tween_callback(SOL.dialogue.bind("vampire_battle_70p2"))
			tw.tween_callback(set_state.bind(BattleActor.States.COOLDOWN))
		, CONNECT_ONE_SHOT)
		damage += (character.health - damage) - character.max_health * 0.7
	elif (character.health - damage) / character.max_health < 0.5 and progress == 1:
		progress = 2
		debuffing_spirits.append("vampeanuts")
		SOL.dialogue("vampire_battle_50p")
		create_tween().tween_property(vampire, "modulate:a", 0.77, 7)
		damage += (character.health - damage) - character.max_health * 0.5
	elif (character.health - damage) / character.max_health < 0.3 and progress == 2:
		progress = 3
		SOL.dialogue("vampire_battle_30p")
		SOL.dialogue_closed.connect(func():
			vampire.z_index = 0
			SOL.set_deferred("dialogue_open", true)
			var tw := create_tween()
			tw.tween_property(vampire, "modulate:a", 1.1, 0.2)
			get_viewport().get_camera_2d().add_trauma(0.5)
			tw.tween_interval(1)
			tw.finished.connect(func():
				SOL.dialogue("vampire_battle_30p2")
			, CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT)
		damage += (character.health - damage) - character.max_health * 0.3
	elif character.health - damage <= 0.0:
		progress = 4
		animate("death")
		SND.play_song("", 20)
		SND.play_sound(preload("res://sounds/spirit/vampdeath.ogg"))
		SOL.dialogue_open = true
		var tw := create_tween()
		if background:
			tw.tween_property(background, "modulate", Color.BLACK, 2)
		else:
			tw.tween_interval(2)
		tw.tween_callback(SOL.dialogue.bind("vampire_battle_dead"))
	return damage


func _comments(actor: BattleActor) -> void:
	if actor == reference_to_opposing_array[0]:
		var greg := actor
		if (comments_made == 0 and reference_to_opposing_array[1].character.health > 0 and
				greg.character.spirits.size() < 1 and progress == 3):
			SOL.dialogue("vampire_steal_all_spirits")
			comments_made += 1

