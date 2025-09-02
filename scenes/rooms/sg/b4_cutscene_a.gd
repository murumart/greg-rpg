extends Area2D

const Grandma = preload("res://scenes/characters/overworld/scr_grandma_overworld.gd")

@export var cam: Camera2D
@export var greg: PlayerOverworld

@onready var grandma: Grandma = $Grandma

var seen: bool:
	set(to): DAT.set_data("sg_b4_cutscene_seen", to)
	get: return DAT.get_data("sg_b4_cutscene_seen", false)


func _ready() -> void:
	if seen:
		queue_free()
		return
	body_entered.connect(_cutscene.unbind(1))


func _cutscene() -> void:
	if seen: return
	DAT.capture_player("cutscene")
	greg.animate("walk_right")
	grandma.sanimate("walk_right")
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(cam, ^"global_position", $CamPos.global_position, 2.0)
	if is_instance_valid(SND.current_song_player):
		tw.parallel().tween_property(SND.current_song_player, ^"volume_linear", 0.15, 1.0)
	await tw.finished
	var dlg := DialogueBuilder.new().set_char("grandma_talk")
	dlg.al("what?? he's already in my [color=%s]secret garden[/color]??" % dlg.FLOWERCOLOR)
	dlg.al("i didn't expect that he'd get here so fast!").scallback(func() -> void:
		grandma.sanimate("shock")
		grandma.tanim_shake(10, 1.0)
	)
	dlg.al("you, cat-faced freaks! what have you done to stop him!?").scallback(func() -> void:
		grandma.sanimate("smile")
		grandma.tanim_shake(5, 1.0)
	)
	dlg.clear_char().al(dlg.SGD + "We... uh, meowed... at him?")
	dlg.al(dlg.SGD + "We also threw a bunch of household appliances at him, as you requested.").scallback(func() -> void:
		grandma.sanimate("walk_down", 0.0)
	)
	dlg.set_char("grandma_talk").al("household appliances?").scallback(func() -> void:
		grandma.sanimate("smile")
		grandma.tanim_shake(5, 1.0)
	)
	dlg.al("you cat-faced idiots!! those were supposed to be symbolic!!").scallback(func() -> void:
		grandma.sanimate("halgful_right")
		grandma.tanim_shake(15, 2.0)
	)
	dlg.al("getting work done!! finishing up chores!! profiting from lost couch-coins!!").scallback(func() -> void:
		grandma.sanimate("halgful", 1.1)
	)
	dlg.al("the machines were supposed to remind you to do your job!!")
	dlg.al("but he already did what you were supposed to, and better.").scallback(func() -> void:
		grandma.sanimate("smile")
		grandma.tanim_bounce(2.0)
	)
	dlg.al("all i really needed now was that you stall him until i'm ready!")
	dlg.al("graahh!! i've had it with you!!").scallback(func() -> void:
		grandma.sanimate("halgful", 1.7)
		grandma.tanim_shake(20, 4.0)
	)
	dlg.al("i'll destroy you all after i'm done with him...").scallback(func() -> void:
		grandma.sanimate("smile")
		grandma.tanim_bounce(2.0)
	)
	dlg.al("...if there's anything left after he's through here! ha ha!!")
	dlg.al("bye, losers!")
	await dlg.speak_choice()
	grandma.sanimate("zoom")
	grandma.particles(1.0)
	tw = create_tween()
	tw.tween_property(grandma, "global_position", grandma.global_position + Vector2(0, -500), 1.0)
	await tw.finished
	dlg.clear()
	dlg.al(dlg.SGD + "...well, this stinks.")
	dlg.al(dlg.SGD + "Who's gonna tell her that we're abstract constructs with no physis to destroy?")
	dlg.al(dlg.SGD + "Neither does the [color=%s]SECRET GARDEN[/color], but she broke in here anyway...")
	dlg.al(dlg.SGD + "I won't take any chances! I'm outta here!").scallback(func() -> void:
		var a := $Crowd/SgCatOwl3
		var t := create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_IN)
		t.tween_property(a, "global_position", a.global_position + Vector2(50, 0), 1.4)
	)
	dlg.al(dlg.SGD + "Self-preservation instinct? That's a new feeling for me!")
	dlg.al(dlg.SGD + "Me too!! Let's all self-preserve!!")
	await dlg.speak_choice()
	tw = create_tween()
	tw.tween_property($Crowd, "global_position", $Crowd.global_position + Vector2(80, 0), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_interval(1.0)
	tw.tween_property(cam, ^"position", Vector2(0, -9), 1.0)
	if is_instance_valid(SND.current_song_player):
		tw.parallel().tween_property(SND.current_song_player, ^"volume_linear", 1.0, 1.0)
	await tw.finished
	DAT.free_player("cutscene")
	$Crowd.queue_free()
	seen = true
