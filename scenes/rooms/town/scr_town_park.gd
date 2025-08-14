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
	var flowers_c := DAT.flower_progress(greg.inventory)

	fear = maxi(fear, flowers_c - 1)

	if not tarikas_talked:
		tarikas_talked = true
		dlg.add_line(dlg.ml("mh. you're blocking the sunlight."))
		dlg.add_line(dlg.ml("...haven't seen you around here before."))
		dlg.add_line(dlg.ml("boy... keep it down."))
		dlg.add_line(dlg.ml("don't do anything interesting. we've had enough of that... already."))
		await dlg.speak_choice()

	while true:
		var aval_choices := [&"bye", &"now"]
		if flowers_c > 1:
			aval_choices.append(&"flowers")
		for t in unlocked_topics:
			aval_choices.append(t)
		dlg.reset().add_line(dlg.ml("what brings you here?" if fear < 2 else "...").schoices(aval_choices))
		var choice := await dlg.speak_choice()
		if choice == &"bye":
			if fear < 2:
				dlg.reset().add_line(dlg.ml("mh. step out the way of the sun..."))
				dlg.add_line(dlg.ml("and come back... later."))
				await dlg.speak_choice()
			break
		elif choice == &"now":
			dlg.reset()
			if fear < 2:
				dlg.add_line(dlg.ml("advice on what to do now? mh."))
			if greg.level < 5:
				dlg.al("you look weak... and frail.")
				dlg.al("back as little kids, we used to go into the tall grass...")
				dlg.al("...and fight whatever... sprung up to attack us.")
				dlg.al("that grew character. you clearly... didn't do that.")
			elif greg.level < 20:
				dlg.al("if i were you...")
				dlg.al("i'd be careful... loitering around town.")
				dlg.al("the new generation has been growing up into...")
				dlg.al("...a bunch of thugs.")
				dlg.al("you contend for the same niche...")
			elif greg.level < 30:
				if not DAT.get_data("fisherwoman_fought", false):
					if fear == 0:
						dlg.al("it's... good weather for a stroll by the lake today.")
						dlg.al("i wouldn't go. the fish are too... aggressive.")
						dlg.al("i know someone who fell in the lake... once.")
						dlg.al("when he managed to clamber out, he was... changed...")
						dlg.al("extremely muscular and wise from all the combat experience...")
						dlg.al("...from fighting for his life with the underwater creatures.")
						dlg.al("he later died in a car accident,")
					else:
						dlg.al("the fisher-woman...")
						dlg.al("don't bother her with your... trife... troubles...")
				else:
					dlg.al("...")
			await dlg.speak_choice()
		elif choice == &"fisher":
			fear = maxi(1, fear)
			DAT.set_data("tarikas_talked_fisherwoman", true)
			dlg.reset()
			dlg.al("the lady at the lake, fishing...")
			dlg.al("...the way you appeared here, it reminds me of her.")
			dlg.al("mh, but she stays out of trouble... dilligently...")
			dlg.al("something weighs her down.")
			dlg.al("but you... might feel encouraged by the very same thing.")

			await dlg.speak_choice()
		elif choice == &"flowers":
			fear = maxi(2, fear)
			dlg.reset()
			if fear < 3:
				dlg.al("the... [color=%s]flowers[/color]?" % dlg.FLOWERCOLOR)
				dlg.al("...")
				dlg.al("very... symbolic. what... flowers do you mean...?")
			else:
				dlg.al("...")
			await dlg.speak_choice()
		else:
			break
