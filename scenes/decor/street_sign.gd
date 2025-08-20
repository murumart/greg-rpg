extends StaticBody2D

@export var dialogue_key: StringName


func _ready() -> void:
	$InspectArea.key = dialogue_key
