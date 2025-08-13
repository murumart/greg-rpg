extends Node2D

@onready var guru: OverworldCharacter = $StatusEffectGuru
@onready var tarikas: OverworldCharacter = $Tarikas

var tarikas_talked: bool:
	set(to): DAT.set_data("tarikas_talked_to", to)
	get: return DAT.get_data("tarikas_talked_to", false)
var unlocked_topics: PackedStringArray:
	set(to): DAT.set_data("tarikas_topics", to)
	get: return DAT.get_data("tarikas_topics", [])
var fear: int:
	get: return DAT.get_data("tks_fear", 0)
	set(to): DAT.set_data("tks_fear", to)


func _ready() -> void:
	if not unlocked_topics:
		unlocked_topics = []
	tarikas.inspected.connect(_on_tarikas_inspected)
	if DAT.get_data("known_status_effects", []).is_empty():
		pass
		guru.queue_free()


func _on_tarikas_inspected() -> void:
	var dlg := DialogueBuilder.new().set_char("tarikas")
	var greg := ResMan.get_character("greg")

	if not tarikas_talked:
		tarikas_talked = true
		dlg.add_line(dlg.ml("mh. you're blocking the sunlight."))
		dlg.add_line(dlg.ml("...haven't seen you around here before."))
		dlg.add_line(dlg.ml("boy... keep it down."))
		dlg.add_line(dlg.ml("don't do anything interesting. we've had enough of that already."))
		await dlg.speak_choice()

	while true:
		var aval_choices := [&"bye", &"now"]
		for t in unlocked_topics:
			aval_choices.append(t)
		dlg.reset().add_line(dlg.ml("what brings you here?" if fear < 2 else "...").schoices(aval_choices))
		var choice := await dlg.speak_choice()
		if choice == &"bye":
			if fear < 2:
				dlg.reset().add_line(dlg.ml("mh. step out the way of the sun..."))
				dlg.add_line(dlg.ml("and come back later."))
				await dlg.speak_choice()
			break
		elif choice == &"now":
			dlg.reset()
			if fear < 2:
				dlg.add_line(dlg.ml("advice on what to do now? mh."))
			if greg.level < 5:
				dlg.add_line(dlg.ml("the tall grass..."))
				dlg.add_line(dlg.ml("if you really want to do something good..."))
				dlg.add_line(dlg.ml("walk in tall grass, and something might jump out to attack you."))
				dlg.add_line(dlg.ml("it'd be good if you took those threats on."))
				dlg.add_line(dlg.ml("fighting grass matches your skill level perfectly, boy."))
			elif greg.level < 15:
				dlg.add_line(dlg.ml("this town has a crime problem."))
				dlg.add_line(dlg.ml("and an animal problem..."))
				dlg.add_line(dlg.ml("it would be mutually beneficial for us..."))
				dlg.add_line(dlg.ml("...if you tussled a bit with them."))
			elif greg.level < 40:
				unlocked_topics.append("flower")
				dlg.add_line(dlg.ml("if you're really after the [color=%s]flower[/color]" % DialogueBuilder.FLOWERCOLOR))
				dlg.add_line(dlg.ml("fuck my lyfe").scallback(func() -> void: queue_free()))
				await dlg.speak_choice()
				break

			await dlg.speak_choice()
		elif choice == &"fisher":
			DAT.set_data("tarikas_talked_fisherwoman", true)
			dlg.reset().al("the lady at the lake, fishing...")
			dlg.reset().al("")
		else:
			break
