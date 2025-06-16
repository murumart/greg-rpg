extends BattleEnemy

const ZoomBullet = preload("res://scenes/characters/battle_enemies/woods_guy_fight/zoom_bullet.gd")
const AppearBullet = preload("res://scenes/characters/battle_enemies/woods_guy_fight/appear_bullet.gd")
const FlowerBoy = preload("res://scenes/characters/battle_enemies/woods_guy_fight/flower_boy.gd")
const BirdAttrack = preload("res://scenes/characters/battle_enemies/woods_guy_fight/bird_attrack.gd")
const Warning = preload("res://scenes/characters/battle_enemies/woods_guy_fight/warning.gd")

const BOARD_CENTRE := Vector2(0, -26)
const TRANS_TIME := 0.75
const MINUSO := Vector2.ONE * -1

@onready var board: Node2D = $Battle
@onready var greeble: PlayerOverworld = $Battle/Greg
@onready var hit_area: Area2D = $Battle/Greg/HitArea

var attack_ix := 0
var attacks: Array[Callable]


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
		#func() -> void:
			#await circle_attack(0.6, 1, 0, 32, 0, board.global_position)
			#,
		#func() -> void:
			#await random_attack(4, 0.5)
			#,
		#func() -> void:
			#await circle_attack(1.4, 4, 0, 36, PI * 0.25, board.global_position)
			#,
		#func() -> void:
			#await random_attack(10, 0.3),
		#func() -> void:
			#await circle_attack(0.8, 8, 0.7, 36)
			#,
		#func() -> void:
			#for i in 3:
				#var fb := FlowerBoy.create(rng, greeble, 2)
				#fb.global_position = board.global_position + Vector2(rng.randf_range(38, 56) * (-1 if rng.randf() < 0.5 else 1), -38)
				#board.add_child(fb)
				#await Math.timer(0.6)
			#await Math.timer(3)
			#,
		#func() -> void:
			#var b := BirdAttrack.create(rng, 0.8)
			#board.add_child(b)
			#b.global_position = board.global_position + Vector2(0, -38)
			#await Math.timer(7)
			#b.queue_free()
			#,
		func () -> void:
			var b := Warning.create(rng, Rect2(0, 0, 4, 2))
			board.add_child(b)
			await b.attack()
			b = Warning.create(rng, Rect2(0, 2, 4, 2))
			board.add_child(b)
			await b.attack()
			b = Warning.create(rng, Rect2(0, 0, 2, 4))
			board.add_child(b)
			await b.attack()
			,
		func() -> void:
			for i in 6:
				var fb := FlowerBoy.create(rng, greeble, 2, 15.0)
				fb.global_position = board.global_position + Vector2(rng.randf_range(38, 56) * (-1 if rng.randf() < 0.5 else 1), -38)
				board.add_child(fb)
				await Math.timer(0.6)
			await Math.timer(3)
			,
		func() -> void:
			await circle_attack(0.6, 40, 0.05, 40, 0, board.global_position)
			await circle_attack(0.6, 40, 0.05, 40, 0, board.global_position)
			await circle_attack(0.6, 40, 0.05, 40, 0, board.global_position)
			await circle_attack(0.6, 40, 0.05, 40, 0, board.global_position)
			,
	]


func act() -> void:
	var greglvl := ResMan.get_character("greg").level
	if greglvl < 50:
		ai_action()
		return
	ignore_my_finishes = true
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
	tw.parallel().tween_property(board, "rotation", TAU * 4, TRANS_TIME)
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
	if is_instance_valid(target):
		target.hurt(20, Genders.BRAIN)


func pick_attack() -> void:
	await attacks[attack_ix].call()
	attack_ix += 1
	if attack_ix >= attacks.size():
		attack_ix = attacks.size() - rng.randi() % 2


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
