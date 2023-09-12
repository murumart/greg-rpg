extends Room

@export var force_atgirl := false
@onready var ugc := Math.child_dict($Decoration/UshankaGuyCutscene) as Dictionary


func _ready() -> void:
	super._ready()
	if LTS.gate_id == LTS.GATE_EXIT_BIKING:
		mail_man_welcome_after_biking()
		return
	if can_ushanka_guy_cutscene():
		ugc.animator.play("cutscene_1")
	else:
		$Decoration/UshankaGuyCutscene.queue_free()
		ugc.clear()
	pink_haired_girl_setup(force_atgirl)


func _on_interaction_area_on_interact() -> void:
	if not DAT.get_data("has_talked_to_mail_man", false):
		mail_man_welcome()
	elif not DAT.get_data("asked_about_mail_man_job", false):
		mail_man_talk()
	else:
		mail_man_jobtalk()
	if LTS.gate_id == "town-postoffice" and not get_meta("interacted", false):
		DAT.incri("post_office_enters", 1)
		set_meta("interacted", true)


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
	var time := wrapi(DAT.seconds, 0, DAT.ATGIRL_CYCLE)
	var atgirl := $Decoration/Atgirl
	if not Math.inrange(time / 4.0, 300, 600) and not force:
		atgirl.queue_free()
		return
	if DAT.get_data("atgirl_progress", 0) > 3:
		atgirl.default_lines.clear()
		atgirl.default_lines.append("atgirl_postoffice_explain")


func can_ushanka_guy_cutscene() -> bool:
	if not DAT.get_data("has_talked_to_mail_man", false): return false
	if DAT.get_data("biking_games_finished", 0) < 2: return false
	if DAT.get_data("post_office_enters", 0) < 3: return false
	if LTS.gate_id == LTS.GATE_EXIT_BIKING: return false
	if DAT.get_data("witnessed_ushanka_guy_cutscene", false): return false
	DAT.set_data("witnessed_ushanka_guy_cutscene", true)
	return true


func dial(key: String) -> void:
	SOL.dialogue(key)
	ugc.animator.pause()
	SOL.dialogue_closed.connect(func():ugc.animator.play(), CONNECT_ONE_SHOT)


func stop_music() -> void:
	SND.play_song("", 0.5)


func play_music() -> void:
	SND.play_song(music)

