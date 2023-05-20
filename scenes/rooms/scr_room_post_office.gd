extends Room

@export var force_phg := false


func _ready() -> void:
	super._ready()
	if LTS.gate_id == LTS.GATE_EXIT_BIKING:
		mail_man_welcome_after_biking()
	pink_haired_girl_setup(force_phg)


func _on_interaction_area_on_interact() -> void:
	if not DAT.get_data("has_talked_to_mail_man", false):
		mail_man_welcome()
	elif not DAT.get_data("asked_about_mail_man_job", false):
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
	var biked : int = DAT.get_data("biking_games_finished", 0)
	if biked < 2:
		SOL.dialogue("mail_man_welcomeback")
	else:
		SOL.dialogue("mail_man_afterbiking")


func pink_haired_girl_setup(force := false) -> void:
	var time := wrapi(DAT.seconds, 0, DAT.PHG_CYCLE)
	var phg := $Decoration/PHG
	if not Math.inrange(time / 4.0, 300, 600) and not force:
		phg.queue_free()
		return
	if DAT.get_data("phg_progress", 0) > 3:
		phg.default_lines.clear()
		phg.default_lines.append("phg_postoffice_explain")

