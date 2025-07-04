extends Room

const MimTalker = preload("res://scenes/rooms/postoffice/src_mail_man_talker.gd")

@onready var mail_man: OverworldCharacter = $Decoration/MailMan
@onready var notes: Sprite2D = $Decoration/Paper/Notes
@onready var ushanka_guy_cutscene := $Decoration/UshankaGuyCutscene
@onready var talker: MimTalker = $MailManTalker

@export var force_atgirl := false

var hes_dead := false
var interacted := false


func _option_init(opt: Dictionary) -> void:
	if LTS.gate_id == LTS.GATE_EXIT_BIKING:
		ready.connect(func() -> void:
			mail_man.enter_a_state_of_conversation()
			await talker.returntalk(opt["biking_results"])
			mail_man.finish_talking()
		)


func _ready() -> void:
	super._ready()
	talker.job_request.connect(enter_job)
	if (not DAT.get_data("vampire_fought", false)
			and ResMan.get_character("greg").level > 49
			and LTS.gate_id != LTS.GATE_EXIT_BIKING):
		hes_dead = true
		notes.show()
		ushanka_guy_cutscene.consequences()
	elif can_ushanka_guy_cutscene():
		ushanka_guy_cutscene.start()
	else:
		ushanka_guy_cutscene.cleanup()

	pink_haired_girl_setup(force_atgirl)


func _on_interaction_area_on_interact() -> void:
	if not hes_dead:
		talker.interact()
		if LTS.gate_id == "town-postoffice" and not interacted:
			DAT.incri("post_office_enters", 1)
		interacted = true
	else:
		# he's dead
		SOL.dialogue("vampire_note")


func speak(key: StringName) -> void:
	mail_man.default_lines = [key]
	mail_man.interacted()


func enter_job() -> void:
	SND.play_song("")
	LTS.level_transition("res://scenes/biking/scn_biking_tutorial.tscn")


func pink_haired_girl_setup(force := false) -> void:
	var time := wrapi(DAT.seconds, 0, DAT.ATGIRL_CYCLE)
	var atgirl := $Decoration/Atgirl as OverworldCharacter
	if not Math.inrange(time, time * 0.25, 0.5) and not force:
		atgirl.queue_free()
		return
	if hes_dead:
		atgirl.queue_free()
		return
	if DAT.get_data("atgirl_progress", 0) > 3:
		atgirl.default_lines.clear()
		atgirl.default_lines.append("atgirl_postoffice_explain")


func can_ushanka_guy_cutscene() -> bool:
	if DAT.get_data("biking_games_finished", 0) < 2: return false
	if talker.relationship < 5: return false
	if DAT.get_data("post_office_enters", 0) < 3: return false
	if LTS.gate_id == LTS.GATE_EXIT_BIKING: return false
	if LTS.gate_id == LTS.GATE_LOADING: return false
	if DAT.get_data("witnessed_ushanka_guy_cutscene", false): return false
	if DAT.get_data("vampire_fought", false): return false
	if ResMan.get_character("greg").level > 49: return false
	if DAT.get_data("uguy_following", false): return false
	DAT.set_data("witnessed_ushanka_guy_cutscene", true)
	return true
