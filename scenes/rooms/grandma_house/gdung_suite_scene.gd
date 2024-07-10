class_name GDUNGSuiteScene extends Area2D

static var greg_in: GDUNGSuiteScene
signal greg_entered(which: GDUNGSuiteScene)

const SCENE := preload("res://scenes/rooms/grandma_house/gdung_suite.tscn")
var suite: GDUNGSuite
@onready var coll := $CollisionShape2D


static func create(_suite: GDUNGSuite) -> GDUNGSuiteScene:
	var creation := SCENE.instantiate()
	creation.suite = _suite
	return creation


func _ready() -> void:
	coll.shape = RectangleShape2D.new()
	global_position = suite.get_position() * 16.0
	coll.shape.size = suite.get_rect().size * 16.0
	coll.position += coll.shape.size * 0.5
	body_entered.connect(func(a):
		greg_in = self
		self.greg_entered.emit(self)
	)
