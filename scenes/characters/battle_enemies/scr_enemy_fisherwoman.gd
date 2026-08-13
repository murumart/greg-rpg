extends BattleEnemy

const Blocks = preload("res://scenes/fishing/blocks.gd")
const Hook = preload("res://scenes/fishing/hook.gd")
const Spawner = preload("res://scenes/fishing/spawner.gd")
const Camera = preload("res://scenes/tech/scr_camera.gd")

@onready var blocks: Blocks = $FishingMinigame/Blocks
@onready var hook: Hook = $FishingMinigame/Hook
@onready var fishing_minigame: Node2D = $FishingMinigame
@onready var choir: AudioStreamPlayer = $FishingMinigame/Choir

@onready var particles: GPUParticles2D = $Sprite2D/Particles
@onready var sprite: Sprite2D = $Sprite2D
@onready var gregparticles: ParticleProcessMaterial = $FishingMinigame/Hook/Look/Sprite2D/Particles.process_material

var camera: Camera

var dlg := DialogueBuilder.new()
var greg: BattleActor


func _ready() -> void:
	super()
	remove_child(fishing_minigame)
	get_parent().add_sibling(fishing_minigame)
	greg = reference_to_opposing_array[0]
	camera = get_window().get_camera_2d()


func act() -> void:
	if will_final_attack():
		await dialogue()
		animate("flee")
		await its_fishing_time()
		fled.emit(self)
	else:
		await dialogue()
		super()
		character.speed = 1.0


func hurt(amt: float, gnd: int) -> void:
	if character.health_perc() < 0.5:
		amt *= 0.5
	if character.health_perc() < 0.25:
		amt *= 0.5
	if character.health_perc() < 0.125:
		amt *= 0.5
	if character.health - _hurt_damage(amt, gnd) <= 0:
		dlg.reset().set_char("fisherwoman").set_emo("brood")
		dlg.add_line(dlg.ml("...i understand."))
		dlg.add_line(dlg.ml("i'm glad it's over, now."))
		DAT.set_data("fisherwoman_violently", true)
		await dlg.speak_choice()
	await super(amt, gnd)
	character.speed = 65.0


var d_progress := 0

func will_final_attack() -> bool:
	return d_progress > 10


func dialogue() -> void:
	dlg.reset().set_char("fisherwoman").set_emo("brood")
	match d_progress:
		0: dlg.al("go away.")
		1: dlg.al("i knew you'd come back to toy with me.")
		2: dlg.al("you made a mistake by bringing me here.")
		3: dlg.al("giving me the [color=%s]flower[/color] was a mistake, too." % DialogueBuilder.FLOWERCOLOR)
		4: dlg.al("are you finally correcting your mistake now?")
		5: dlg.al("confiscating this power...")
		6: dlg.al("...i don't remember you smelling this bad, though.")
		8: dlg.al("...")
		10: dlg.al("...!")
		11:
			dlg.al("you know what? whatever!!")
			dlg.al("this is why i'm here...")
			dlg.al("but, i'll tell you officially: remember it!")
			dlg.al("i reject my [color=%s]flower[/color]!" % DialogueBuilder.FLOWERCOLOR).stext_speed(0.8)
			dlg.al("if you want it back so bad...")
			dlg.al("go fish for it!")
	d_progress += 1
	if not dlg.is_empty():
		await dlg.speak_choice()


signal doneful
func its_fishing_time() -> void:
	camera.resolution_scale_factor = 0.5
	camera.zoom = Math.v2(2.0)
	camera.update_window_stuff()
	choir.play()
	SND.play_song("", 99.0)
	blocks.noise.frequency = 0.123
	hook.fish_caught.connect(func(a: FishingFish) -> void:
		a.caught()
		choir.stop()
		SND.play_song("extremophile", 99)
		hook.state = Blocks.FG.States.STOP
		blocks.state = Blocks.FG.States.STOP
		await Math.timer(2.0)
		doneful.emit()
	)
	hook.hit.connect(func() -> void:
		await greg.handle_payload(get_attack_payload(greg))
		if greg.character.health <= 0:
			hook.state = Blocks.FG.States.STOP
			blocks.state = Blocks.FG.States.STOP
	)

	var flower: Node2D
	flower = Spawner.FISH_LOAD.instantiate()
	flower.is_fish = false
	flower.moving = true
	flower.speed = 0
	flower.ymoving = false
	flower.item = &"flower_hollyhock"
	flower.global_position = Vector2(0, 300)

	fishing_minigame.add_child(flower)
	var tw := create_tween()
	const max_speed := 150.0
	var wait_time := remap(greg.character.level, 20, 99, 8.0, 30.0)
	tw.tween_property(fishing_minigame, ^"modulate:a", 1.0, 1.0).from(0)
	tw.parallel().tween_property(hook, ^"position", Vector2(0, -60), 0.9)
	tw.parallel().tween_property(choir, ^"volume_db", 3, 0.9)
	tw.parallel().tween_property(choir, ^"pitch_scale", 1.0, 0.9)
	hook.state = Blocks.FG.States.MOVE
	blocks.state = Blocks.FG.States.MOVE
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).parallel().tween_method(func(a: float) -> void:
		hook.speed = a
		blocks.speed = a
	, 50.0, max_speed, wait_time)
	tw.parallel().set_ease(Tween.EASE_OUT).tween_property(choir, ^"pitch_scale", 2.0, wait_time * 1.3)
	tw.parallel().set_ease(Tween.EASE_OUT).tween_property(gregparticles, ^"initial_velocity_max", 120.0, wait_time * 1.3)
	tw.tween_property(flower, ^"position:y", 0.0, wait_time)
	tw.parallel().set_ease(Tween.EASE_IN_OUT).tween_method(func(a: float) -> void:
		hook.speed = a
		blocks.speed = a
	, max_speed, 0.0, wait_time * 0.75)
	tw.parallel().tween_property(choir, ^"pitch_scale", 0.75, wait_time)
	tw.parallel().tween_property(choir, ^"volume_db", -10, wait_time)
	tw.parallel().tween_property(gregparticles, ^"initial_velocity_max", 10.0, wait_time)
	tw.parallel().tween_property(blocks.noise, ^"frequency", 0.02, wait_time + 1.0)
	await doneful
