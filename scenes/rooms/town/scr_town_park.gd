extends Node2D

@onready var guru: OverworldCharacter = $StatusEffectGuru
@onready var tarikas: OverworldCharacter = $Tarikas

var tarikas_talked: bool:
	set(to): DAT.set_data("tarikas_talked_to", to)
	get: return DAT.get_data("tarikas_talked_to", false)
var unlocked_topics: PackedStringArray:
	set(to): DAT.set_data("tarikas_topics", to)
	get: return DAT.get_data("tarikas_topics", [])


func _ready() -> void:
	if not unlocked_topics:
		unlocked_topics = []
	tarikas.inspected.connect(_on_tarikas_inspected)
	if DAT.get_data("known_status_effects", []).is_empty():
		pass
		guru.queue_free()


func _on_tarikas_inspected() -> void:
	const FLOWERCOLOR := "99ff61"
	var dlg := DialogueBuilder.new().set_char("tarikas")
	var greg := ResMan.get_character("greg")

	if not tarikas_talked:
		tarikas_talked = true
		dlg.add_line(dlg.ml("mh. you're blocking the sunlight."))
		dlg.add_line(dlg.ml("...haven't seen you around here before."))
		dlg.add_line(dlg.ml("boy... keep it down."))
		dlg.add_line(dlg.ml("don't do anything interesting. that's my advice."))
		await dlg.speak_choice()

	while true:
		var aval_choices := [&"bye", &"advice"]
		for t in unlocked_topics:
			aval_choices.append(t)
		dlg.reset().add_line(dlg.ml("what brings you here?").schoices(aval_choices))
		var choice := await dlg.speak_choice()
		if choice == &"bye":
			dlg.reset().add_line(dlg.ml("mh. step out the way of the sun..."))
			dlg.add_line(dlg.ml("and come back later."))
			await dlg.speak_choice()
			break
		elif choice == &"advice":
			dlg.reset().add_line(dlg.ml("advice? mh."))
			if greg.level < 5:
				dlg.add_line(dlg.ml("the tall grass..."))
				dlg.add_line(dlg.ml("if you walk there, something might jump out and attack you."))
				dlg.add_line(dlg.ml("something weak, but plentiful."))
				dlg.add_line(dlg.ml("something to practice on."))
			elif greg.level < 15:
				dlg.add_line(dlg.ml("this town has a crime problem."))
				dlg.add_line(dlg.ml("and an animal problem..."))
				dlg.add_line(dlg.ml("it would be mutually beneficial for us..."))
				dlg.add_line(dlg.ml("...if you tussled a bit with them."))
			elif greg.level < 40:
				unlocked_topics.append("flower")
				dlg.add_line(dlg.ml("if you're really after the [color=%s]flower[/color]" % FLOWERCOLOR))
				dlg.add_line(dlg.ml("fuck my lyfe").scallback(func() -> void: queue_free()))
				await dlg.speak_choice()
				break

			await dlg.speak_choice()
		else:
			break
