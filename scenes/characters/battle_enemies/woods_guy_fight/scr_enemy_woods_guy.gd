extends BattleEnemy

const ZoomBullet = preload("res://scenes/characters/battle_enemies/woods_guy_fight/zoom_bullet.gd")
const AppearBullet = preload("res://scenes/characters/battle_enemies/woods_guy_fight/appear_bullet.gd")
const FlowerBoy = preload("res://scenes/characters/battle_enemies/woods_guy_fight/flower_boy.gd")
const BirdAttrack = preload("res://scenes/characters/battle_enemies/woods_guy_fight/bird_attrack.gd")
const Warning = preload("res://scenes/characters/battle_enemies/woods_guy_fight/warning.gd")

const TREE := preload("res://scenes/decor/scn_tree.tscn")

const TX_WOODSMAN = preload("res://sprites/characters/battle/woodsman/woodsman.png")
const TX_WOODSMAN_LOOK = preload("res://sprites/characters/battle/woodsman/woodsman_look.png")

const BOARD_CENTRE := Vector2(0, -26)
const TRANS_TIME := 0.75
const MINUSO := Vector2.ONE * -1
const DEFAULT_INVTIME := 0.5

@onready var board: Node2D = $Battle
@onready var greeble: PlayerOverworld = $Battle/Greg
@onready var hit_area: Area2D = $Battle/Greg/HitArea
@onready var sprite: Sprite2D = $Sprite

var attack_ix := 0
var attacks: Array[Callable]
var invtime := 0.0
var max_invtime := DEFAULT_INVTIME


func _ready() -> void:
	super()
	greeble.state = PlayerOverworld.States.NOT_FREE_MOVE
	hit_area.area_entered.connect(hit_area_entered)
	board.hide()
	reference_to_opposing_array[0].died.connect(func(_a):
		greeble.state = PlayerOverworld.States.NOT_FREE_MOVE
		greeble.sprite.rotate(PI * 0.5)
	)
	hide_board()
	attacks = [
		func() -> void:
			await circle_attack(0.6, 1, 0, 32, 0, board.global_position)
			,
		func() -> void:
			await random_attack(7, 0.4)
			,
		func() -> void:
			await circle_attack(1.4, 4, 0, 42, PI * 0.25, board.global_position)
			await Math.timer(0.8)
			await circle_attack(1.3, 4, 0, 36, PI, board.global_position)
			,
		func() -> void:
			await random_attack(12, 0.3)
			await warning_attack(Rect2(0, 0, 4, 2)) # watch me beat it.
			,
		func() -> void:
			flowerboy_attack(4, 1.2, 1, 60)
			await Math.timer(4)
			,
		func() -> void:
			await circle_attack(0.9, 8, 1.1, 36)
			,
		func() -> void:
			for i in 4: # kill or be killed
				await circle_attack(1.4, 4, 0, 48, TAU * (i / 8.0), board.global_position)
				await Math.timer(0.8)
			,
		func() -> void:
			flowerboy_attack(6, 0.8, 2, 60.0)
			await Math.timer(5)
			,
		func() -> void:
			var t := TREE.instantiate()
			board.add_child(t)
			t.position = Vector2(7, 21)
			await warning_attack(Rect2(0, 0, 4, 3))
			await warning_attack(Rect2(0, 1, 4, 3))
			await warning_attack(Rect2(0, 0, 3, 4))
			await warning_attack(Rect2(1, 0, 3, 4))
			t.queue_free() # sorry about the tree
			,
		func() -> void:
			for i in 8:
				await circle_attack(1.4, 4, 0, 48, TAU * (i / 16.0), board.global_position)
				await Math.timer(0.8)
			,
		func() -> void:
			flowerboy_attack(6, 0.6, 4, 15.0)
			await Math.timer(7)
			,
		func() -> void:
			await bird_attack(0.8, 7)
			,
		func() -> void:
			random_attack(12, 0.3)
			await warning_attack(Rect2(0, 0, 4, 2))
			await warning_attack(Rect2(0, 2, 4, 2))
			random_attack(24, 0.2)
			await warning_attack(Rect2(2, 2, 2, 2))
			await warning_attack(Rect2(0, 0, 2, 2))
			await warning_attack(Rect2(2, 0, 2, 2))
			await warning_attack(Rect2(0, 2, 2, 2))
			,
		func() -> void:
			circle_attack(7.0, 10, 0.1, 42, 0, board.global_position)
			circle_attack(7.0, 10, 0.1, 42, 0, board.global_position)
			await bird_attack(0.5, 10)
			await Math.timer(1.0)
			,
		func() -> void:
			await circle_attack(0.6, 40, 0.05, 40, 0, board.global_position)
			await circle_attack(0.6, 40, 0.05, 40, 0, board.global_position)
			await circle_attack(0.6, 40, 0.05, 40, 0, board.global_position)
			await circle_attack(0.6, 40, 0.05, 40, 0, board.global_position)
			,
		func() -> void:
			flowerboy_attack(6, 0.6, 4, 15.0)
			await Math.timer(6)
			,
		func() -> void:
			for i in 8:
				await circle_attack(1.4, 4, 0, 48, TAU * (i / 16.0), board.global_position)
				await Math.timer(0.8)
			,
		func() -> void:
			await bird_attack(0.8, 7)
			,
		func() -> void:
			await warning_attack(Rect2(0, 0, 4, 3))
			await warning_attack(Rect2(0, 1, 4, 3))
			await warning_attack(Rect2(0, 0, 3, 4))
			await warning_attack(Rect2(1, 0, 3, 4))
			,
	]


func _process(delta: float) -> void:
	super(delta)
	if greeble.state == PlayerOverworld.States.FREE_MOVE:
		invtime = maxf(0.0, invtime - delta)
		if invtime > 0:
			greeble.modulate.a = 0.2 + (sin(invtime * 30) + 1) * 0.3
		else:
			greeble.modulate.a = 1


func act() -> void:
	var greglvl := ResMan.get_character("greg").level
	ignore_my_finishes = true
	sprite.texture = TX_WOODSMAN_LOOK
	var dlgstr := "woods_guy_battle_" + str(turn + 1)
	if SOL.dialogue_exists(dlgstr):
		SOL.dialogue(dlgstr)
		await SOL.dialogue_closed
	sprite.texture = TX_WOODSMAN
	await reveal_board()
	await Math.timer(0.7)
	await pick_attack()
	await Math.timer(2.0)
	await hide_board()
	ignore_my_finishes = false
	turn_finished()


func reveal_board() -> void:
	var tw := create_tween()
	greeble.position = Vector2.ZERO
	board.show()
	tw.tween_property(board, "scale", Vector2.ONE, TRANS_TIME)
	tw.parallel().tween_property(board, "modulate", Color.WHITE, TRANS_TIME)
	tw.parallel().tween_property(board, "rotation", TAU * 1, TRANS_TIME)
	await tw.finished
	greeble.state = PlayerOverworld.States.FREE_MOVE


func hide_board() -> void:
	var tw := create_tween()
	greeble.state = PlayerOverworld.States.NOT_FREE_MOVE
	tw.tween_property(board, "scale", Vector2.ONE * 0.2, TRANS_TIME)
	tw.parallel().tween_property(board, "modulate", Color.TRANSPARENT, TRANS_TIME)
	tw.parallel().tween_property(board, "rotation", 0, TRANS_TIME)
	await tw.finished
	board.hide()


func hit_area_entered(area: Area2D) -> void:
	var target := pick_target()
	if is_instance_valid(target) and invtime <= 0 and greeble.state == PlayerOverworld.States.FREE_MOVE:
		target.hurt(20, Genders.BRAIN)
		invtime = max_invtime


func pick_attack() -> void:
	if attack_ix >= attacks.size():
		attack_ix = attacks.size() - rng.randi_range(1, 4)
	await attacks[attack_ix].call()
	attack_ix += 1


func circle_attack(
	speed: float,
	n: int,
	delay: float,
	distance: float,
	initial_angle: float = 0.0,
	target := MINUSO
) -> void:
	for i in n:
		var pos := Vector2.from_angle(initial_angle + TAU / n * i) * -distance + board.global_position
		var target_pos := (pos + pos.direction_to(
			greeble.global_position if target == MINUSO else target)
			* distance * 2)
		var zb := ZoomBullet.create(target_pos, speed)
		board.add_child(zb)
		zb.global_position = pos
		zb.attack()
		await Math.timer(delay)


func random_attack(n: int, delay: float, gridlock := false) -> void:
	for i in n:
		var pos := Vector2(rng.randf_range(-2, 2), rng.randf_range(-1, 3))
		if gridlock:
			pos = pos.floor()
		pos *= 16
		pos += board.global_position
		var b := AppearBullet.create()
		b.global_position = pos
		board.add_child(b)
		await Math.timer(delay)


func flowerboy_attack(n: int, delay: float, flowercount: int, flowerspeed: float) -> void:
	for i in n:
		var fb := FlowerBoy.create(rng, greeble, flowercount, flowerspeed)
		var side := (-1 if rng.randf() < 0.5 else 1)
		fb.global_position = board.global_position + Vector2(rng.randf_range(38, 56) * side, -38)
		board.add_child(fb)
		await Math.timer(delay)


func warning_attack(rect: Rect2) -> void:
	var b := Warning.create(rng, rect)
	board.add_child(b)
	await b.attack()


func bird_attack(delay: float, time: float) -> void:
	max_invtime = 0.67
	var b := BirdAttrack.create(rng, delay)
	board.add_child(b)
	b.global_position = board.global_position + Vector2(0, -38)
	await Math.timer(time)
	b.queue_free()
	max_invtime = DEFAULT_INVTIME
