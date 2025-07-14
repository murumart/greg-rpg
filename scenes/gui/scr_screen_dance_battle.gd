class_name ScreenDanceBattle extends Control

signal kill_arrows
signal end(data: Dictionary)

const STREAK_CONGRATS := ["", "", "ok", "good!", "cool!", "great!", "wonderful!", "amazing!", "fantastic.", "extraordinary.", "super duper!", "gjepörgkpoaüjapowäef", "i walked into an electric fence!"]

@onready var falling_arrows: Node2D = $FallingArrows
@onready var mbc := $MusBarCounter as MusBarCounter
@onready var dancer: Sprite2D = $Dancer
@onready var animal_dancer: Sprite2D = $AnimalDancer
@onready var score_text: HBoxContainer = $ScoreDisplay/ScoreTexts
@onready var streak_label: Label = $ScoreDisplay/StreakLabel

@onready var good_sound: AudioStreamPlayer = $GoodSound
@onready var bad_sound: AudioStreamPlayer = $BadSound
@onready var win_sound: AudioStreamPlayer = $WinSound
@onready var player_splash: Node2D = $InTheRye/PlayerSplash
@onready var enemy_splash: Node2D = $EnCatcher/EnemySplash
@onready var greg_ancestors: GPUParticles2D = $Dancer/GregAncestors
@onready var animal_ancestors: GPUParticles2D = $AnimalDancer/AnimalAncestors

@export var accuracy_curve: Curve
var tutorial := false

var active := false:
	set(to):
		if not to:
			kill_arrows.emit()
		else:
			tutorial = not DAT.get_data("dance_battle_tutorialed", false)
			if tutorial:
				SOL.dialogue("dance_battle_tutorial")
				DAT.set_data("dance_battle_tutorialed", true)
		active = to

var enemy_reference: EnemyAnimal
var enemy_level := 1
var target_reference: BattleActor
var target_level := 1

var beat := 0
var beats_to_play := 40

var hits := 0
var streak := 0
var score := 0.0
var enemy_hits := 0
var enemy_streak := 0
var enemy_score := 0.0


func _ready() -> void:
	mbc.new_beat.connect(_new_beat)
	reset()


func _physics_process(delta: float) -> void:

	if active:
		score = maxf(0.0, score - delta * 0.5)
		enemy_score = maxf(0.0, enemy_score - delta * 0.5)

	# DEBUG
	#if Input.is_key_pressed(KEY_9):
		#SND.play_song("lion")
		#reset()
		#active = true


func reset() -> void:
	dancer.region_rect.position = Vector2()
	animal_dancer.region_rect.position = Vector2()
	hits = 0
	streak = 0
	score = 0
	enemy_hits = 0
	enemy_score = 0
	enemy_streak = 0
	beat = 0
	greg_ancestors.amount_ratio = 0.0
	animal_ancestors.amount_ratio = 0.0
	streak_label_fun(0, "")
	set_score_text()


func _new_beat() -> void:
	if not active:
		return
	if not SOL.dialogue_open:
		beat += 1
	#if streak > 0:
		#dance(dancer)
	#if enemy_streak > 0:
		#dance(animal_dancer)
	if beat > beats_to_play:
		return
	var beat_to_test := 2 if not tutorial else 4
	if beat % (beat_to_test) == 0:
		create_tween().tween_property(score_text, "modulate", Color.WHITE, 0.2).from(Color.YELLOW)
		if SOL.dialogue_open:
			return
		create_arrow()
		create_arrow(1)
	else:
		if SOL.dialogue_open:
			return
		if randf() <= 0.22:
			if randf() <= 0.5:
				create_arrow()
				create_arrow(1)


func create_arrow(alignment := 0) -> void:
	var arrow := Arrow.new()
	var dir := (randi() % 4) as Arrow.Dirs
	arrow.direction = dir
	arrow.accuracy_curve = accuracy_curve
	arrow.enemy_difficulty = remap(enemy_level, 1, 99, 0.36, 0.99)
	falling_arrows.add_child(arrow)
	#var bps := mbc.bpm / 60.0
	var spb := 60.0 / mbc.bpm
	var base_speed := remap(enemy_level, 1, 99, 75, 200)
	arrow.speed = randfn(base_speed, 8) # pixels per sec
	if tutorial:
		arrow.speed *= 0.75

	arrow.position.y = -(arrow.speed * spb) * 4
	arrow.scale.x = 1 + arrow.speed * spb * 4 * 0.01
	arrow.scale.y = arrow.scale.x
	var trail := preload("res://scenes/vfx/scn_vfx_dance_arrow_trail.tscn").instantiate()
	arrow.add_child(trail)
	trail.material.set_shader_parameter("line_colour", arrow.COLORS[dir])
	if alignment == 1:
		arrow.enemy = true
		arrow.global_position.x = 110
		arrow.can_receive_input = false
		arrow.enemy_action.connect(_enemy_action)
	else:
		arrow.hit.connect(_success_hit)
		arrow.miss.connect(_fail_miss)
	kill_arrows.connect(arrow.die)


func _success_hit(accuracy: float) -> void:
	if not active:
		return
	dance(dancer)
	streak += 1
	hits += 1
	score += accuracy * maxi(streak, 1)

	set_score_text(0)
	good_sound.play()
	SOL.vfx("spark_splash", player_splash.global_position, {parent = player_splash})
	greg_ancestors.amount_ratio = streak / float(STREAK_CONGRATS.size())
	check_end()


func _fail_miss() -> void:
	if not active:
		return
	dancer.texture.region.position.y = 32
	dancer.texture.region.position.x = 96
	streak = 0
	set_score_text()
	greg_ancestors.amount_ratio = 0.0
	bad_sound.play()
	target_reference.handle_payload(enemy_reference.get_attack_payload(target_reference))
	check_end()


func _enemy_action(success: bool, accuracy: float) -> void:
	if not active:
		return
	if success:
		if tutorial and beat % 4 == 0:
			_enemy_action(false, -1)
			return
		dance(animal_dancer)
		enemy_streak += 1
		enemy_score += accuracy * maxi(enemy_streak, 1)
		enemy_hits += 1
		greg_ancestors.amount_ratio = enemy_streak / float(STREAK_CONGRATS.size())
		SOL.vfx("spark_splash", enemy_splash.global_position, {parent = enemy_splash})
	else:
		animal_dancer.texture.region.position.y = 32
		animal_dancer.texture.region.position.x = 96
		greg_ancestors.amount_ratio = 0.0
		enemy_streak = 0
	set_score_text(1)


func set_score_text(gain := -1) -> void:
	var sz := STREAK_CONGRATS.size()
	var congrats: String = STREAK_CONGRATS[mini(streak, sz - 1)]
	var pscore := snappedf(score + hits, 0.1)
	var enscore := snappedf(enemy_score + enemy_hits, 0.1)

	var l := score_text.get_child(0) as Label
	var r := score_text.get_child(1) as Label

	l.text = str(pscore)
	r.text = str(enscore)

	if gain > -1:
		var tw := create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		var p: float = [l, r][gain].position.y
		tw.tween_property([l, r][gain], "position:y", p - 5, 0.06)
		tw.tween_property([l, r][gain], "position:y", p, 0.1)

	streak_label_fun(streak, congrats)


func dance(who: Sprite2D) -> void:
	who.texture.region.position.y = randi() % 2 * 32
	who.texture.region.position.x = randi() % 3 * 32
	squash(who)


func squash(who: Sprite2D) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var endsc := Vector2.ONE
	if randf() < 0.5:
		endsc = Vector2(0.8, 1.2)
	else:
		endsc = Vector2(1.2, 0.8)
	tw.tween_property(who, "scale", endsc, 0.1)
	tw.tween_property(who, "scale", Vector2.ONE, 0.1)


func check_end() -> void:
	if (target_reference.character.health <= 0
		or enemy_reference.character.health <= 0
		or beat > beats_to_play
	):
		end_game()


func end_game() -> void:
	kill_arrows.emit()
	active = false
	var pscore := snappedf(score + hits, 0.1)
	var enscore := snappedf(enemy_score + enemy_hits, 0.1)

	if target_reference.character.health > 0:
		set_score_text()
		streak_label_fun(99, "danceoff end!!")
		if pscore > enscore:
			win_sound.play()
	else:
		pscore = -999
	get_tree().create_timer(2.0).timeout.connect(_ended)


func _ended() -> void:
	var pscore := snappedf(score + hits, 0.1)
	var enscore := snappedf(enemy_score + enemy_hits, 0.1)
	var end_data := {
		"player_score": pscore,
		"enemy_score": enscore,
		"enemy_reference": enemy_reference,
		"player_reference": target_reference
	}
	end.emit(end_data)


func streak_label_fun(intensity: int, text: String) -> void:
	var sl := streak_label
	var ls := sl.label_settings
	if intensity == 0:
		ls.font_color = Color.WHITE
		var tw := create_tween()
		tw.tween_property(ls, "shadow_color", Color(0.042, 0.0, 0.299, 0.745), 0.1)
		tw.parallel().tween_property(ls, "font_size", 8, 0.2)
	else:
		var tgthue := wrapf(ls.shadow_color.ok_hsl_h + 0.1 * intensity, 0.0, 1.0)
		var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(ls, "shadow_color:ok_hsl_h", tgthue, 0.1)
		tw.parallel().tween_property(ls, "shadow_color:ok_hsl_l", ls.shadow_color.ok_hsl_l + tgthue * 0.1, 0.1)
		if intensity % 4 == 0:
			tw.parallel().tween_property(ls, "font_size", ls.font_size + 1, 0.2)
		shake(sl, streak * 0.5)
	streak_label.text = text


func shake(n: Control, intensity: float) -> void:
	var tw := n.create_tween()
	var pos := n.position
	var maxim := 15.0
	for i in maxim:
		var dec := (maxim - i) / maxim
		tw.tween_property(n, "position", n.position + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * intensity * dec, 0.3 / maxim)
	tw.tween_property(n, "position", pos, 0.05)



class Arrow extends Sprite2D:
	enum Dirs {LEFT, RIGHT, DOWN, UP}

	signal hit(accuracy: float)
	signal miss
	signal enemy_action(success: bool, accuracy: float)

	const INPUTS := [&"move_left", &"move_right", &"move_down", &"move_up"]
	const COLORS := [
		Color(0.5, 0.0, 0.0),
		Color(0.5, 0.0, 0.5),
		Color(0.0, 0.0, 0.5),
		Color(0.0, 0.5, 0.0),
	]

	var accuracy_curve: Curve

	var direction := Dirs.LEFT
	var enemy := false
	var enemy_difficulty := 0.66
	var speed := 60.0
	var grace_area := 10
	var yspace := 0
	var active := false
	var moving := true
	var can_receive_input := true
	var received_input := false


	func _ready() -> void:
		texture = preload("res://sprites/gui/spr_dancer_arrows.png")
		region_enabled = true
		region_rect = Rect2(0, int(direction) * 16, 16, 16)


	var cyc := 0
	func _physics_process(delta: float) -> void:
		if moving:
			global_position.y += delta * speed
			scale.x -= delta * speed * 0.01
			scale.y -= delta * speed * 0.01
		var ypos := position.y

		if ypos >= -19 and not received_input:
			active = true

		if can_receive_input and active:
			var dir := cyc as Dirs
			var input := Input.is_action_pressed(INPUTS[cyc])
			var succ_hit := (dir == direction and input and
				Math.inrange(ypos, yspace - grace_area, yspace + grace_area))

			if input and not succ_hit:
				received_input = true
				get_miss()
			elif succ_hit:
				received_input = true
				get_hit()

			if ypos > grace_area:
				get_miss()

		elif enemy and ypos >= randi_range(-grace_area/2, grace_area/2) and active:
			var succ := randf() <= enemy_difficulty
			if succ:
				get_hit()
			else:
				get_miss()
			active = false
			received_input = true

		if ypos > grace_area:
			modulate.a -= delta * 5
			if modulate.a <= 0.0:
				queue_free()

		cyc = wrapi(cyc + 1, 0, 4)


	func get_hit():
		moving = false
		active = false
		var tw := create_tween().set_parallel(true)
		tw.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
		tw.tween_property(self, "modulate:a", 0.0, 0.2)
		var distance := absf(position.y)
		var accuracy := accuracy_curve.sample_baked(remap(distance, 0.0, grace_area, 0.0, 1.0))
		if not enemy:
			hit.emit(accuracy)
			can_receive_input = false
		else:
			enemy_action.emit(true, accuracy)


	func get_miss():
		modulate = Color.RED
		active = false
		if not enemy:
			miss.emit()
			can_receive_input = false
		else:
			enemy_action.emit(false, -1)


	func die() -> void:
		var tw := self.create_tween().set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(self, "modulate:a", 0.0, 0.3)
		tw.tween_callback(self.queue_free)
