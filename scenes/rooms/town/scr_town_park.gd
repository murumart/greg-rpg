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
	if DAT.get_data("tarikas_solar_done", false) or DAT.get_data("tarikas_done", false):
		tarikas.queue_free()
	if DAT.get_data("known_status_effects", []).is_empty():
		pass
		guru.queue_free()


var cokay := false
var cfinal := false
func _on_tarikas_inspected() -> void:
	var dlg := DialogueBuilder.new().set_char("tarikas")
	var greg := ResMan.get_character("greg")
	var flowers_c := DAT.flower_progress(greg.inventory)

	if cfinal:
		dlg.al("...")
		await dlg.speak_choice()
		return

	if flowers_c == 7:
		SND.play_song("extremophile", 0.1, {pitch_scale = 0.2})
		DAT.set_data("tarikas_done", true)
		dlg.al("...seven [color=%s]flowers[/color]." % dlg.FLOWERCOLOR)
		dlg.al("you are missing an eighth.")
		dlg.al("despite my... warnings.")
		dlg.al("despite my stalling...")
		dlg.al("...seven [color=%s]flowers[/color]." % dlg.FLOWERCOLOR)
		dlg.al("i hold the eighth...")
		dlg.al("...")
		dlg.al("there's nothing else for me to do than to give... it to you.")
		dlg.clear_char().al("(you received the begonia.)").sitem_to_give(&"flower_begonia")
		dlg.set_char("tarikas").al("you have enough... now.")
		dlg.al("... she's waiting.")
		dlg.al("fare well.")
		dlg.al("i hope we don't meet... again.")

		cfinal = true
		await dlg.speak_choice()
		return

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
		dlg.reset().add_line(dlg.ml("what brings you here?" if flowers_c < 2 else "...").schoices(aval_choices))
		var choice := await dlg.speak_choice()
		if choice == &"bye":
			if flowers_c < 2:
				dlg.reset().add_line(dlg.ml("mh. step out the way of the sun..."))
				dlg.add_line(dlg.ml("and come back... later."))
				await dlg.speak_choice()
			break
		elif choice == &"now":
			dlg.reset()
			if flowers_c < 2:
				dlg.al("advice on what to do now? mh.")
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
			elif greg.level < 40:
				if not DAT.get_data("fisherwoman_fought", false):
					if flowers_c == 1:
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
					dlg.al("now there is nothing to do but to... loiter.")
					dlg.al("for a while.")
			elif greg.level < 50:
				if not DAT.get_data("vampire_fought", false):
					dlg.al("another newcomer in town...")
					dlg.al("i figured one wouldn't be... the end of it...")
					dlg.al("someone ought to keep an eye on her...")
				else:
					dlg.al("(whistle)")
					dlg.al("i should go to the store... soon...")
					dlg.al("(whistle...)")
			elif greg.level < 60:
				if not DAT.get_data("president_fought", false):
					dlg.al("i decided against going shopping.")
					dlg.al("there is someone there...")
				else:
					dlg.al("hm? he's... gone? i can go shopping?")
					dlg.al("i'll... i'll...")
					dlg.al("maybe not... today.")
			elif greg.level < 70:
				if not cokay:
					dlg.al("maybe it'd help to go on a...")
					dlg.al("calming... walk in the woods?")
					dlg.al("there's a path to there around the north of town.")
					if "forest" in DAT.get_data("visited_rooms", []):
						dlg.al("...you've been there...?")
						cokay = true
						dlg.al("...you survived... okay... okay...")
				else:
					dlg.al("...that's... nice...")
			elif greg.level < 80:
				if not "town_east" in DAT.get_data("visited_rooms"):
					dlg.al("i was thinking about walking to... east of town.")
					dlg.al("but the police were blocking the road, last i checked...")
					dlg.al("i wonder if they still are...?")
				else:
					dlg.al("i don't think i'm going to east of town like this...")

			await dlg.speak_choice()
		elif choice == &"fisher":
			DAT.set_data("tarikas_talked_fisherwoman", true)
			dlg.reset()
			if not DAT.get_data("fisherwoman_fought", false):
				dlg.al("the lady at the lake, fishing...")
				dlg.al("...the way you appeared here, it reminds me of her.")
				dlg.al("mh, but she stays out of trouble... dilligently...")
				dlg.al("something weighs her down.")
				dlg.al("but you... might feel encouraged by the very same thing.")
			else:
				dlg.al("she's gone...?")
				dlg.al("...")
			await dlg.speak_choice()
		elif choice == &"vampire":
			dlg.al("i... she was a vampire... i see.")
			dlg.al("there isn't much cursed blood left... in the world.")
			dlg.al("...thankfully.")
			dlg.al("but every now and then, someone finds some...")
			dlg.al("and... ingests some.")
			dlg.al("the power that follows can be immense...")
			dlg.al("...depending on the [color=%s]strain[/color]." % dlg.VAMPCOLOR)
			dlg.al("...")
			dlg.al("the... the [color=#0f0]green demon[/color]?")
			dlg.al("...is that so...")

			await dlg.speak_choice()
		elif choice == &"president":
			dlg.reset()
			dlg.al("he is a... broken man.")
			dlg.al("i don't think \"beacon archipelago\" is much more than a single rock...")
			dlg.al("...but no one dares sail near... there.")
			dlg.al("none should have this... magnitude... of power over nature.")
			await dlg.speak_choice()
		elif choice == &"flowerboy":
			dlg.reset()
			dlg.al("i don't know much... about him.")
			dlg.al("he doesn't talk to us at all.")
			dlg.al("unless... he finds someone.")
			dlg.al("someone he thinks... has potential.")
			dlg.al("...")
			dlg.al("it'd be best if you stayed... away.")
			await dlg.speak_choice()
		elif choice == &"mayor":
			dlg.reset()
			dlg.al("so you met the... mayor.")
			dlg.al("he hasn't actually been in power for a long... time...")
			dlg.al("...but his antics have been fun to watch...")
			dlg.al(".... .... window to the spirit world?")
			dlg.al("...did he...")
			dlg.al("...you did see [color=0f0]it[/color], didn't you...")
			dlg.al("i think... he was caught at an... opportune moment.")
			await dlg.speak_choice()
		elif choice == &"flowers":
			dlg.reset()
			if flowers_c < 2:
				dlg.al("the... [color=%s]flowers[/color]?" % dlg.FLOWERCOLOR)
				dlg.al("...")
				dlg.al("very... symbolic. what... flowers do you mean...?")
			elif flowers_c < 4:
				dlg.al("the... [color=%s]flowers[/color]." % dlg.FLOWERCOLOR)
				dlg.al("i understand that you're... collecting them...")
				dlg.al("maybe it will turn out for the best.")
				dlg.al("...that is a foolish hope.")
				dlg.al("considering... whose... whose... ...")
				dlg.al("...")
			elif flowers_c < 6:
				dlg.al("growth...")
				dlg.al("that is what a [color=%s]flower[/color] means...")
				dlg.al("what it beckons...")
				dlg.al("you will... finish growing... eventually.")
				dlg.al("what's a ripe fruit good for, think...?")
				dlg.al("...")
			elif flowers_c < 7:
				dlg.al("the [color=0f0]danger[/color] of the flowers.")
				dlg.al("i can't tell you much... more, but...")
				dlg.al("do you think you're better than them?")
				dlg.al("do you think the same won't... happen to you?")
				dlg.al("your power... might just be... enough...")

			else:
				dlg.al("...")
			await dlg.speak_choice()
		else:
			break
