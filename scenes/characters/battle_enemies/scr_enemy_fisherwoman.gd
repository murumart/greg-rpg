extends BattleEnemy


const Blocks = preload("res://scenes/fishing/blocks.gd")
const Hook = preload("res://scenes/fishing/hook.gd")
const Spawner = preload("res://scenes/fishing/spawner.gd")

@onready var blocks: Blocks = $FishingMinigame/Blocks
@onready var hook: Hook = $FishingMinigame/Hook
@onready var fishing_minigame: Node2D = $FishingMinigame
@onready var choir: AudioStreamPlayer = $FishingMinigame/Choir

@onready var particles: GPUParticles2D = $Sprite2D/Particles
@onready var sprite: Sprite2D = $Sprite2D

var dlg := DialogueBuilder.new()
var greg: BattleActor


func _ready() -> void:
	super()
	greg = reference_to_opposing_array[0]


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
	if character.health - _hurt_damage(amt, gnd) <= 0:
		dlg.reset().set_char("fisherwoman").set_emo("brood")
		dlg.add_line(dlg.ml("...i understand."))
		dlg.add_line(dlg.ml("i'm glad it's over, now."))
		DAT.set_data("fisherwoman_violently", true)
		await dlg.speak_choice()
	await super(amt, gnd)
	character.speed = 65.0


func will_final_attack() -> bool:
	return d_progress > 10


var d_progress := 0
func dialogue() -> void:
	dlg.reset().set_char("fisherwoman").set_emo("brood")
	match d_progress:
		0: dlg.add_line(dlg.ml("go away."))
		1: dlg.add_line(dlg.ml("i knew you'd come back to toy with me."))
		2: dlg.add_line(dlg.ml("you made a mistake by bringing me here."))
		3: dlg.add_line(dlg.ml("giving me the [color=%s]flower[/color] was a mistake, too." % Math.FLOWERCOLOR))
		4: dlg.add_line(dlg.ml("so, you're finally correcting your mistake."))
		6: dlg.add_line(dlg.ml("...i don't remember you smelling this bad, though."))
		8: dlg.add_line(dlg.ml("..."))
		10: dlg.add_line(dlg.ml("...!"))
		11:
			dlg.add_line(dlg.ml("you know what? whatever!!"))
			dlg.add_line(dlg.ml("this is why i'm here..."))
			dlg.add_line(dlg.ml("but, i'll tell you officially, now."))
			dlg.add_line(dlg.ml("i reject my [color=%s]flower[/color]!" % Math.FLOWERCOLOR).stext_speed(0.8))
			dlg.add_line(dlg.ml("if you want it back so bad..."))
			dlg.add_line(dlg.ml("well, go fish for it!"))
	d_progress += 1
	if not dlg.is_empty():
		await dlg.speak_choice()


signal doneful
func its_fishing_time() -> void:
	choir.play()
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
	tw.set_trans(Tween.TRANS_CUBIC).parallel().tween_method(func(a: float) -> void:
		hook.speed = a
		blocks.speed = a
	, 50.0, max_speed, wait_time * 1.3)
	tw.parallel().tween_property(choir, ^"pitch_scale", 2.0, wait_time * 1.3)
	tw.tween_property(flower, ^"position:y", 0.0, wait_time)
	tw.parallel().tween_method(func(a: float) -> void:
		hook.speed = a
		blocks.speed = a
	, max_speed, 0.0, wait_time)
	tw.parallel().tween_property(choir, ^"pitch_scale", 0.75, wait_time)
	tw.parallel().tween_property(choir, ^"volume_db", -10, wait_time)
	tw.parallel().tween_property(blocks.noise, ^"frequency", 0.02, wait_time + 1.0)
	await doneful
