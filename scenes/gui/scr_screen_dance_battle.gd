class_name ScreenDanceBattle extends Control

signal kill_arrows
signal end(data: Dictionary)

const STREAK_CONGRATS := ["", "ok", "good!", "cool!", "wonderful!", "amazing!", "truly great.", "extraordinary.", "super duper!", "gjepörgkpoaüjapowäef", "i walked into an electric fence!"]

@onready var falling_arrows: Node2D = $FallingArrows
@onready var debug: Label = $debug
@onready var mbc := $MusBarCounter as MusBarCounter
@onready var dancer: Sprite2D = $Dancer
@onready var animal_dancer: Sprite2D = $AnimalDancer
@onready var score_text: RichTextLabel = $ScoreText

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
		score -= delta * 0.5
		enemy_score -= delta * 0.5

	# DEBUG
	#if Input.is_key_pressed(KEY_9):
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
	set_score_text()


func _new_beat() -> void:
	if not active:
		return
	if not SOL.dialogue_open:
		beat += 1
	if streak > 0:
		player_dance()
	if enemy_streak > 0:
		enemy_dance()
	if beat > beats_to_play:
		return
	var beat_to_test := 2 * (2 * int(tutorial))
	if beat % (beat_to_test + 2) == 0:
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
			if randf() <= 0.5:
				create_arrow(1)


func create_arrow(alignment := 0) -> void:
	var arrow := Arrow.new()
	arrow.accuracy_curve = accuracy_curve
	falling_arrows.add_child(arrow)
	var bps := mbc.bpm / 60.0
	arrow.speed = randf_range(120, 150) # pixels per sec
	if tutorial:
		arrow.speed *= 0.75

	arrow.position.y = -arrow.speed * bps
	var trail := preload("res://scenes/vfx/scn_vfx_dance_arrow_trail.tscn").instantiate()
	arrow.add_child(trail)
	if alignment == 1:
		arrow.enemy = true
		arrow.global_position.x = 110
		arrow.can_receive_input = false
		arrow.enemy_action.connect(_enemy_action)
	else:
		arrow.hit.connect(_success_hit)
		arrow.miss.connect(_fail_miss)
	kill_arrows.connect(arrow.queue_free)


func _success_hit(accuracy: float) -> void:
	if not active: return
	player_dance()
	streak += 1
	hits += 1
	score += accuracy * maxi(streak, 1)
	set_score_text()
	if beat > beats_to_play: end_game()


func _fail_miss() -> void:
	if not active: return
	dancer.region_rect.position.y = 32
	dancer.region_rect.position.x = 96
	streak = 0
	set_score_text()
	if beat > beats_to_play: end_game()


func _enemy_action(success := true) -> void:
	if not active: return
	if success:
		if tutorial and beat % 4 == 0:
			_enemy_action(false)
			return
		enemy_dance()
		enemy_streak += 1
		enemy_score += 2.0 * maxi(enemy_streak, 1)
		enemy_hits += 1
	else:
		animal_dancer.region_rect.position.y = 32
		animal_dancer.region_rect.position.x = 96
		enemy_streak = 0
	set_score_text()


func set_score_text() -> void:
	var sz := STREAK_CONGRATS.size()
	var congrats: String = STREAK_CONGRATS[mini(streak, sz - 1)]
	var pscore := snappedf(score + hits, 0.1)
	var enscore := snappedf(enemy_score + enemy_hits, 0.1)

	var text := "[center]%s[/center]

[left]%s[/left] [right]%s[/right]" % [congrats, pscore, enscore]

	score_text.text = text


func player_dance() -> void:
	dancer.region_rect.position.y = randi() % 2 * 32
	dancer.region_rect.position.x = randi() % 3 * 32


func enemy_dance() -> void:
	animal_dancer.region_rect.position.y = randi() % 2 * 32
	animal_dancer.region_rect.position.x = randi() % 3 * 32


func end_game() -> void:
	kill_arrows.emit()
	active = false
	var pscore := snappedf(score + hits, 0.1)
	var enscore := snappedf(enemy_score + enemy_hits, 0.1)

	score_text.text =  "[center]dance off end!![/center]

[left]%s[/left] [right]%s[/right]" % [pscore, enscore]
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



class Arrow extends Sprite2D:
	enum Dirs {LEFT, RIGHT, DOWN, UP}

	signal hit(accuracy: float)
	signal miss
	signal enemy_action(success: bool)

	const INPUTS := ["move_left", "move_right", "move_down", "move_up"]

	var accuracy_curve: Curve

	var direction := Dirs.LEFT
	var enemy := false
	var enemy_difficulty := 0.66
	var speed := 60.0
	var grace_area := 14
	var yspace := 99
	var active := false
	var moving := true
	var can_receive_input := true
	var received_input := false


	func _ready() -> void:
		texture = preload("res://sprites/gui/spr_dancer_arrows.png")
		region_enabled = true
		direction = (randi() % 4) as Dirs
		region_rect = Rect2(0, int(direction) * 16, 16, 16)


	var cyc := 0
	func _physics_process(delta: float) -> void:
		if moving: global_position.y += delta * speed
		var ypos := position.y

		if ypos >= 80 and not received_input:
			active = true

		if can_receive_input and active:
			var dir := cyc as Dirs
			var input := Input.is_action_pressed(INPUTS[cyc])
			var succ_hit := (dir == direction and input and
				(ypos > yspace - 14 and ypos < yspace + 14))

			if input and not succ_hit:
				received_input = true
				get_miss()
			elif succ_hit:
				received_input = true
				get_hit()

			if ypos > 112:
				get_miss()

		elif enemy and ypos >= 99 and active:
			var succ := randf() <= enemy_difficulty
			if succ: get_hit()
			else: get_miss()
			enemy_action.emit(succ)
			active = false
			received_input = true

		if position.y > 128:
			modulate.a -= delta * 5
			if modulate.a <= 0.0: queue_free()

		cyc = wrapi(cyc + 1, 0, 4)


	func get_hit():
		moving = false
		active = false
		var tw := create_tween().set_parallel(true)
		tw.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
		tw.tween_property(self, "modulate:a", 0.0, 0.2)
		var distance = absf(99 - position.y)
		var accuracy := accuracy_curve.sample_baked(remap(distance, 0.0, 8.0, 0.0, 1.0))
		if not enemy:
			hit.emit(accuracy)
			can_receive_input = false


	func get_miss():
		modulate = Color.RED
		active = false
		if not enemy:
			miss.emit()
			can_receive_input = false
