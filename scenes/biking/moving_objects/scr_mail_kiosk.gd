extends BikingMovingObject

# it's the mail mannnn!!!! iosk

signal approached
signal finished

const UI_LOAD := preload("res://scenes/biking/scn_mail_kiosk_menu.tscn")

@onready var animator := $AnimationPlayer


func _ready() -> void:
	animator.play("hide")


func open_menu() -> void:
	var menu := UI_LOAD.instantiate()
	menu.closed.connect(func(): finished.emit())
	menu.game_reference = get_parent()
	SOL.add_ui_child(menu)


# sliiiiiiiiiiiiiiiide to the left
func _on_area_2d_area_entered(_area: Area2D) -> void:
	emit_signal("approached")
	animator.play("enter")
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	await animator.animation_finished
	open_menu()
