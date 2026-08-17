class_name TownPark extends Node2D

@onready var guru: OverworldCharacter = $StatusEffectGuru
@onready var tarikas: OverworldCharacter = $Tarikas
@onready var notif: Sprite2D = $Tarikas/Notif
@onready var notif_anim: SinAnimator = $Tarikas/Notif/SinAnimator

var tarikas_talked: bool:
	set(to): DAT.set_data("tarikas_talked_to", to)
	get: return DAT.get_data("tarikas_talked_to", false)
static var unlocked_topics: PackedStringArray:
	set(to): DAT.set_data("tarikas_topics", to)
	get: return DAT.get_data("tarikas_topics", [])
static var talked_topics: PackedStringArray:
	set(to): DAT.set_data("tarikas_talked_topics", to)
	get: return DAT.get_data("tarikas_talked_topics", [])
var talked_now_last_level: int:
	set(to): DAT.set_data("tarikas_talked_now_last_level", to)
	get: return DAT.get_data("tarikas_talked_now_last_level", 0) 
var talked_flowers_last_level: int:
	set(to): DAT.set_data("tarikas_talked_flowers_last_level", to)
	get: return DAT.get_data("tarikas_talked_flowers_last_level", 0) 

var done: bool:
	set(to): DAT.set_data("tarikas_done", to)
	get: return DAT.get_data("tarikas_done", false) 

var notif_cleared: bool:
	set(to): DAT.set_data("tarikas_notif_cleared", to)
	get: return DAT.get_data("tarikas_notif_cleared", false) 


func _ready() -> void:
	if not unlocked_topics: unlocked_topics = ["now", "bye"]
	if not talked_topics: talked_topics = ["bye"]
	tarikas.inspected.connect(_on_tarikas_inspected)
	if DAT.get_data("tarikas_solar_done", false) or done:
		tarikas.queue_free()
	if DAT.get_data("known_status_effects", []).is_empty():
		pass
		guru.queue_free()
	_check_topics()
	_notif()


var cokay := false
var cfinal := false
func _on_tarikas_inspected() -> void:
	notif.hide()
	notif_cleared = true
	var dlg := DialogueBuilder.new().set_char("tarikas")
	var greg := ResMan.get_character("greg")
	var flowers_c := DAT.flower_progress(greg.inventory)

	if cfinal:
		dlg.al("...")
		await dlg.speak_choice()
		return

	if flowers_c == 6:
		SND.play_song("extremophile", 0.1, {pitch_scale = 0.2})
		done = true
		dlg.al("...six [color=%s]flowers[/color]." % dlg.FLOWERCOLOR)
		dlg.al("you are missing a seventh.")
		dlg.al("despite my... warnings.")
		dlg.al("despite my stalling...")
		dlg.al("...six [color=%s]flowers[/color]." % dlg.FLOWERCOLOR)
		dlg.al("i hold the seventh...")
		dlg.al("...")
		dlg.al("there's nothing else for me to do than to give... it to you.")
		dlg.clear_char().al("(you received the begonia.)").sitem_to_give(&"flower0")
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
		var aval_choices := []
		for t in unlocked_topics:
			aval_choices.append(t)
		aval_choices.sort()
		dlg.reset().add_line(
			dlg.ml("what brings you here?" if flowers_c < 2 else "...")
			.schoices(aval_choices)
			.schoice_visual_setup_callable(func(d: Dictionary) -> void:
				#"button": refbutton,
				#"reference": ref,
				#"nr": i
				if d.reference not in talked_topics:
					d.button.modulate = Color.GREEN
				))
		var choice := await dlg.speak_choice()
		if choice == &"bye":
			if flowers_c < 2:
				dlg.reset().add_line(dlg.ml("mh. step out the way of the sun..."))
				dlg.add_line(dlg.ml("and come back... later."))
				await dlg.speak_choice()
			break
		elif choice == &"now":
			await _what_now(dlg)
		elif choice == &"fisher":
			dlg.reset()
			_mention("fisher")
			DAT.set_data("tarikas_talked_fisherwoman", true)
			dlg.al("the lady at the lake, fishing...")
			if not DAT.get_data("fisherwoman_fought", false):
				dlg.al("...the way you appeared here, it reminds me of her.")
				dlg.al("mh, but she stays out of trouble... diligently...")
				dlg.al("something seems to weigh her down.")
				dlg.al("but you... might be elevated by the very same thing.")
				dlg.al("mh... whatever. keep out of trouble, boy")
			else:
				dlg.al("she's gone...?")
				dlg.al("...mh. boy...")
				dlg.al("you really went... and pestered her like that.")
				dlg.al("she's good at shutting people with stupid questions up...")
				dlg.al("i remember, at the store... one time...")
				dlg.al("a thug was bothering her. asking her 'out'.")
				dlg.al("she kept spouting fish facts back at him, oblivious...")
				dlg.al("...until... he tried to grab her shoulder...")
				dlg.al("and, mh... he lived, but the clerks had trouble...")
				dlg.al("...scraping remains of his clothes off the tile floor.")
				dlg.al("i haven't seen her at... the town, since.")
				dlg.al("why should she come back... anyway?")
				dlg.al("mh. there's no fish here.")
			await dlg.speak_choice()
		elif choice == &"vampire":
			dlg.reset()
			_mention("vampire")
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
			_mention("president")
			dlg.al("he is a... broken man.")
			dlg.al("i don't think \"beacon archipelago\" is much more than a single rock...")
			dlg.al("...but no one dares sail near... there.")
			dlg.al("none should have this... magnitude... of power over nature.")
			await dlg.speak_choice()
		elif choice == &"flowerboy":
			dlg.reset()
			_mention("flowerboy")
			dlg.al("i don't know much... about him.")
			dlg.al("he doesn't talk to us at all.")
			dlg.al("unless... he finds someone.")
			dlg.al("someone he thinks... has potential.")
			dlg.al("...")
			dlg.al("it'd be best if you stayed... away.")
			await dlg.speak_choice()
		elif choice == &"mayor":
			dlg.reset()
			_mention("mayor")
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
			_mention("flowers")
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
			elif flowers_c < 5:
				dlg.al("growth...")
				dlg.al("that is what a [color=%s]flower[/color] means..." % dlg.FLOWERCOLOR)
				dlg.al("what it beckons...")
				dlg.al("you will... finish growing... eventually.")
				dlg.al("what's a ripe fruit good for, think...?")
				dlg.al("...")
			elif flowers_c < 6:
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
	_notif.call_deferred()


func _check_topics() -> void:
	var greg := ResMan.get_character("greg")
	var flowers_c := DAT.flower_progress(greg.inventory)
	if flowers_c > 1 and "flowers" not in unlocked_topics:
		unlocked_topics.append("flowers")
	for l in [5, 20, 40, 50, 60, 70, 80]:
		if greg.level >= l and talked_now_last_level < l:
			_unmention("now")
	for f in [2, 4, 5, 6]:
		if flowers_c >= f and talked_flowers_last_level < f:
			_unmention("flowers")
	if unlocked_topics.size() > talked_topics.size():
		notif_cleared = false


static func add_tarikas_topic(topic: String) -> void:
	if topic not in unlocked_topics:
		unlocked_topics.append(topic)


static func _mention(topic: String) -> void:
	if topic not in talked_topics:
		talked_topics.append(topic)


static func refresh_tarikas_topic(topic: String) -> void:
	if topic not in talked_topics:
		add_tarikas_topic(topic)
		return
	_unmention(topic)


static func _unmention(topic: String) -> void:
	if topic in talked_topics:
		talked_topics.erase(topic)


const NOTIF_ALERT_X = 64.0
const NOTIF_CONTINUE_X = NOTIF_ALERT_X + 7

func _notif() -> void:
	notif.hide()
	notif_anim.speed = 10.0
	notif.region_rect.position.x = NOTIF_ALERT_X
	if not Math.same_contents(talked_topics, unlocked_topics):
		if notif_cleared:
			notif.region_rect.position.x = NOTIF_CONTINUE_X
			notif_anim.speed = 0.0
			notif_anim.offset = 0.125
		notif.show()


func _what_now(dlg: DialogueBuilder) -> void:
	var greg := ResMan.get_character("greg")
	var flowers_c := DAT.flower_progress(greg.inventory)
	dlg.reset()
	talked_now_last_level = greg.level
	_mention("now")
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
			if DAT.visited_room("forest"):
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
