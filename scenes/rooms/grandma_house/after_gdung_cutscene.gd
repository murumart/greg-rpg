extends Node2D

@onready var enter_area: Area2D = $EnterArea
@onready var camera: Camera2D = $"../../Greg/Camera"
@onready var greg: PlayerOverworld = $"../../Greg"
@onready var grandma: OverworldCharacter = $Grandma
@onready var color_container: ColorContainer = $"../../CanvasModulateGroup/ColorContainer"


func _ready() -> void:
	enter_area.body_entered.connect((func():
		pass
	).unbind(1))

