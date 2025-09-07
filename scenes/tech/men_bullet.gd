extends Area2D

const MEN_BULLET = preload("res://scenes/tech/men_bullet.tscn")
const MenBullet = preload("res://scenes/tech/men_bullet.gd")

const DEFA_SPEED := 60.0

@onready var sprite: Sprite2D = $Sprite2D

var direction: Vector2
var speed: float


static func inst(direction_: Vector2, speed_ := DEFA_SPEED) -> MenBullet:
	var b: MenBullet = MEN_BULLET.instantiate()
	b.direction = direction_
	b.speed = speed_
	return b


static func ring(amt: int, speed_ := DEFA_SPEED) -> Node2D:
	var n := Node2D.new()
	var timer := n.create_tween()
	timer.tween_interval(10.0)
	timer.finished.connect(n.queue_free)
	for i: float in amt:
		var k := inst(Vector2.from_angle(TAU * (i / amt)), speed_)
		n.add_child(k)
	return n


func _ready() -> void:
	var t := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(sprite, ^"modulate:a", 1.0, 0.1).from(0.0)
	t.parallel().tween_property(sprite, ^"scale", Vector2.ONE, 0.05).from(Vector2.ZERO)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
