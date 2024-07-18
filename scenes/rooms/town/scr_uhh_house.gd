extends Node2D

@onready var bald_man := $MailInfo as OverworldCharacter


func _ready() -> void:
	if DAT.get_data("heard_mail_info_played", false):
		bald_man.default_lines.append("bald_man_default")
	elif DAT.get_data("biking_games_finished", 0) and DAT.get_data("heard_mail_info", false):
		bald_man.default_lines.clear()
		bald_man.default_lines.append("mail_game_info_played")
		bald_man.inspected.connect(func():
			SOL.dialogue_closed.connect(func():
				bald_man.default_lines.clear()
				SND.play_sound(preload("res://sounds/flee.ogg"))
				var tw := create_tween()
				tw.tween_property(bald_man, "modulate:a", 0.0, 1.0)
				tw.tween_callback(bald_man.queue_free)
			, CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT)
	elif DAT.get_data("biking_games_finished", 0) > 0:
		bald_man.default_lines.append("bald_man_default")
	elif Time.get_datetime_dict_from_system().month == 6:
		bald_man.default_lines.push_front("mail_game_pride_month")
