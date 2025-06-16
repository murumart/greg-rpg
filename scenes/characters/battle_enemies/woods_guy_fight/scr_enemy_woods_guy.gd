extends BattleEnemy

const ZoomBullet = preload("res://scenes/characters/battle_enemies/woods_guy_fight/zoom_bullet.gd")

const BOARD_CENTRE := Vector2(0, -26)
const TRANS_TIME := 0.75
const MINUSO := Vector2.ONE * -1

@onready var board: Node2D = $Battle
@onready var greeble: PlayerOverworld = $Battle/Greg
@onready var hit_area: Area2D = $Battle/Greg/HitArea


func _ready() -> void:
	super()
	greeble.state = PlayerOverworld.States.NOT_FREE_MOVE
	hit_area.area_entered.connect(hit_area_entered)
	board.hide()
	hide_board()


func act() -> void:
	var greglvl := ResMan.get_character("greg").level
	if greglvl < 50:
		ai_action()
		return
	ignore_my_finishes = true
	await reveal_board()
	await circle_attack(0.6, 40, 0.06, 40, 0, board.global_position)
	await circle_attack(0.6, 40, 0.06, 40, 0, board.global_position)
	await circle_attack(0.6, 40, 0.06, 40, 0, board.global_position)
	await circle_attack(0.6, 40, 0.06, 40, 0, board.global_position)


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
	print(area)
	var target := pick_target()
	if is_instance_valid(target):
		attack(target)


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
		zb.global_position = pos
		board.add_child(zb)
		zb.attack()
		await Math.timer(delay)
