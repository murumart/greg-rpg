extends Node2D

var dlg := DialogueBuilder.new()


func _ready() -> void:
	$DoorInspect.inspected.connect(_door)


func _door() -> void:
	dlg.clear()
	var inv := ResMan.get_character("greg").inventory
	dlg.add_line(dlg.ml("it's truly locked..."))
	dlg.add_line(dlg.ml("it'd do good to have a key here."))
	SOL.dialogue_d(dlg.get_dial())
