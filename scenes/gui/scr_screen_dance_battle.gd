class_name ScreenDanceBattle extends Control

signal kill_arrows

@onready var falling_arrows: Node2D = $FallingArrows
@onready var debug: Label = $debug
@onready var mbc: MusBarCounter = $MusBarCounter
@onready var dancer: Sprite2D = $Dancer
@onready var animal_dancer: Sprite2D = $AnimalDancer

var active := false:
	set(to):
		if not to:
			kill_arrows.emit()
		active = to

var enemy_level := 1
var greg_level := 1

var beat := 0

var hits := 0
var streak := 0
var score := 0.0
var enemy_hits := 0
var enemy_streak := 0
var enemy_score := 0.0


# TODO
# figure out scoring.
# connect enemy level and greg level
# make game finite
# figure out loser
# apply damage to loser
# exit back into battle


func _ready() -> void:
	mbc.beat.connect(_new_beat)


func _physics_process(_delta: float) -> void:
	
	debug.text = ("waodosgfpaopoewjas"[randi() % 10] +
		"\n" + "\n" +
		"%s %s %s\n%s %s %s" % [score, hits, streak, enemy_score, enemy_hits, enemy_streak])
	if Input.is_key_pressed(KEY_9):
		active = true


func _new_beat() -> void:
	if not active: return
	beat += 1
	if beat % 2 == 0:
		create_arrow()
		create_arrow(1)
	else:
		if randf() <= 0.22:
			if randf() <= 0.5:
				create_arrow()
			if randf() <= 0.5:
				create_arrow(1)


func create_arrow(alignment := 0) -> void:
	var arrow := Arrow.new()
	falling_arrows.add_child(arrow)
	arrow.speed = mbc.bpm
	var trail := SOL.vfx("dance_arrow_trail", Vector2(50, 0), 
	{"parent": arrow, "z_index": -1})
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
	dancer.region_rect.position.y = randi() % 2 * 32
	dancer.region_rect.position.x = randi() % 3 * 32
	streak += 1
	hits += 1
	score += accuracy


func _fail_miss() -> void:
	if not active: return
	dancer.region_rect.position.y = 32
	dancer.region_rect.position.x = 96
	streak = 0


func _enemy_action(success := true) -> void:
	if not active: return
	if success:
		animal_dancer.region_rect.position.y = randi() % 2 * 32
		animal_dancer.region_rect.position.x = randi() % 3 * 32
		enemy_streak += 1
		enemy_score += 1.1
		enemy_hits += 1
	else:
		animal_dancer.region_rect.position.y = 32
		animal_dancer.region_rect.position.x = 96
		enemy_streak = 0



class Arrow extends Sprite2D:
	enum Dirs {LEFT, RIGHT, DOWN, UP}
	
	signal hit(accuracy: float)
	signal miss
	signal enemy_action(success: bool)
	
	var direction := Dirs.LEFT
	var enemy := false
	var speed := 60.0
	var grace_area := 8
	var yspace := 99
	var active := false
	var can_receive_input := true
	var received_input := false
	const INPUTS := ["move_left", "move_right", "move_down", "move_up"]
	
	
	func _ready() -> void:
		texture = preload("res://sprites/vfx/spr_dancer_arrows.png")
		region_enabled = true
		direction = (randi() % 4) as Dirs
		region_rect = Rect2(0, int(direction) * 16, 16, 16)
	
	
	var cyc := 0
	func _physics_process(delta: float) -> void:
		global_position.y += delta * speed
		var ypos := position.y
		
		if ypos >= 80 and not received_input:
			active = true
		
		if can_receive_input and active:
			var dir := cyc as Dirs
			var input := Input.is_action_pressed(INPUTS[cyc])
			var succ_hit := (dir == direction and input and
				(ypos > yspace - 8 and ypos < yspace + 8))
			
			if input and not succ_hit:
				received_input = true
				get_miss()
			elif succ_hit:
				received_input = true
				get_hit()
		
			if ypos > 112:
				get_miss()
			
		elif enemy and ypos >= 99 and active:
			var succ := bool(randi() % 2)
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
		modulate = Color.GREEN
		active = false
		var distance = absf(99 - position.y)
		var accuracy := remap(distance, 0, 8, 0.75, 1.25)
		if not enemy:
			hit.emit(accuracy)
			can_receive_input = false
	
	
	func get_miss():
		modulate = Color.RED
		active = false
		if not enemy:
			miss.emit()
			can_receive_input = false
