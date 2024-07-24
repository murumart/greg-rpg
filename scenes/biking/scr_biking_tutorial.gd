extends Node2D

var transing := false


func _ready() -> void:
	$RichTextLabel.text = "~biking for dummies~

dear %s,
use [color=#ffff00]arrow keys[/color] to steer my bike.
press [color=#ffff00]%s[/color] to throw mail. [color=#888888]try to aim them at mail boxes![/color]
open your inventory with [color=#ffff00]%s[/color].
do not run my bike into obstacles. [color=#888888]i will strangle you if you damage it.[/color]
[color=#880000]do not crush snails.[/color]
[right][color=#888888]all the best
- mail man
" % [
	("greg" if DAT.get_data("mail_heard_name", false) else "newspaper boy"),
	KeybindsSettings.action_string("ui_accept"),
	KeybindsSettings.action_string("menu"),
	]


func _input(event: InputEvent) -> void:
	if transing: return
	if event.is_action_pressed("ui_accept"):
		transing = true
		LTS.level_transition("res://scenes/biking/scn_biking_game.tscn")
