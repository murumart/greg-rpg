extends BikingMovingObject

signal approached
signal finished

const UI_LOAD := preload("res://scenes/biking/scn_mail_kiosk_menu.tscn")

@onready var animator := $AnimationPlayer


func _ready() -> void:
	animator.play("hide")


func open_menu() -> void:
	var menu := UI_LOAD.instantiate()
	menu.closed.connect(func(): finished.emit())
	SOL.add_ui_child(menu)


func _on_area_2d_area_entered(_area: Area2D) -> void:
	emit_signal("approached")
	animator.play("enter")
	await animator.animation_finished
	open_menu()
