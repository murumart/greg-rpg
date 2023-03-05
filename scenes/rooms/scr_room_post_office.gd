extends Room


func _ready() -> void:
	super._ready()
	if LTS.gate_id == LTS.GATE_EXIT_BIKING:
		mail_man_welcome_after_biking()


func _on_interaction_area_on_interact() -> void:
	if not DAT.A.get("has_talked_to_mail_man", false):
		mail_man_welcome()
	elif not DAT.A.get("asked_about_mail_man_job", false):
		mail_man_talk()
	else:
		mail_man_jobtalk()


func mail_man_welcome() -> void:
	SOL.dialogue("mail_man_hello")
	DAT.set_data("has_talked_to_mail_man", true)

func mail_man_talk() -> void:
	SOL.dialogue("mail_man_talk")

func mail_man_jobtalk() -> void:
	SOL.dialogue_choice = ""
	SOL.dialogue("mail_man_jobtalk")
	await SOL.dialogue_closed
	if SOL.dialogue_choice == "yes":
		SND.play_song("")
		LTS.level_transition("res://scenes/biking/scn_biking_tutorial.tscn")

func mail_man_welcome_after_biking() -> void:
	var biked : int = DAT.A.get("biking_games_finished", 0)
	if biked < 2:
		SOL.dialogue("mail_man_welcomeback")
	else:
		SOL.dialogue("mail_man_afterbiking")
