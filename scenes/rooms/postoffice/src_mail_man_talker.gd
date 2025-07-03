extends Talker

signal job_request

@export var mail_man: OverworldCharacter

static var first_time: bool:
	set(t):
		DAT.set_data("mim_first_time", t)
	get:
		return DAT.get_data("mim_first_time", true)

static var relationship: int:
	set(t):
		DAT.set_data("mim_relationship", t)
	get:
		return DAT.get_data("mim_relationship", 0)

static var games_finished: int:
	set(t):
		DAT.set_data("biking_games_finished", t)
	get:
		return DAT.get_data("biking_games_finished", 0)

var hovered_over_job := false


func interact() -> void:
	mail_man.enter_a_state_of_conversation()

	if first_time:
		await first_time_dialogue()
		mail_man.finish_talking()
		return

	await jobtalk()
	mail_man.finish_talking()
	#dlg.speak()


func first_time_dialogue() -> void:
	var dlg: DB
	var aval_choices := ["job", "you", "me"]
	var mentioned_job := false
	var default_emo := ""
	var exasperation := 0
	var loops := 0
	dlg = DB.new().set_char("mail_man")
	dlg.add_line(dl.mk("welcome to the post office."))
	dlg.add_line(dl.mk("hey... you are the new guy in town, right?"))
	dlg.add_line(dl.mk("i only just heard about you."))
	dlg.add_line(dl.mk("not even settled in yet, and waiting for mail already?"))
	await dlg.speak_choice()
	while true:
		dlg.reset().set_char("mail_man")
		if exasperation >= 2:
			if is_instance_valid(SND.current_song_player) and is_instance_valid(SND.current_song_player.stream):
				create_tween().tween_property(SND.current_song_player, "pitch_scale", 0.97, 1.0)
			dlg.add_line(dl.mk("you are not being useful to anyone here. bye.").semotion("serious"))
			relationship = -5
			await dlg.speak_choice()
			return
		if loops > 0 and not "bye" in aval_choices:
			aval_choices.append("bye")

		var fline := "what are you doing here?"
		if mentioned_job:
			fline = "ask me about this job offer again, later."
		dlg.add_line(dl.mk(fline).schoices(aval_choices).semotion(default_emo))
		first_time = false

		var choice := await dlg.speak_choice()

		loops += 1
		if choice == "job":
			if not mentioned_job:
				dlg.reset().set_char("mail_man")
				dlg.add_line(dl.mk("looking to enter the job market?"))
				dlg.add_line(dl.mk("i can offer something part-time..."))
				dlg.add_line(dl.mk("how does delivering mail by bicycle sound? you could do that."))
				mentioned_job = true
			else:
				dlg.reset().set_char("mail_man")
				dlg.add_line(dl.mk("the job is not anything difficult."))
				dlg.add_line(dl.mk("it is just riding around town on my bicycle..."))
				dlg.add_line(dl.mk("delivering post to awaiting townspeople."))
				dlg.add_line(dl.mk("not a bad job at all."))
				dlg.add_line(dl.mk("i will even show up from time to time and help you."))
				relationship += 1
				exasperation -= 1
				aval_choices.erase("job")
			await dlg.speak_choice()
		elif choice == "you":
			dlg.reset().set_char("mail_man")
			dlg.add_line(dl.mk("...me? what about me?").semotion("serious"))
			dlg.add_line(dl.mk("i am the mail man. who else did you expect at the post office?"))
			aval_choices.erase("you")
			default_emo = "serious"
			exasperation += 1
			await dlg.speak_choice()
		elif choice == "me":
			dlg.reset().set_char("mail_man")
			dlg.add_line(dl.mk("...why are you asking me about yourself?").semotion("serious"))
			if exasperation >= 1:
				dlg.add_line(dl.mk("i do not give a lizard's ass about who you are."))
				exasperation += 1
			else:
				dlg.add_line(dl.mk("i have no idea who you are."))
				dlg.clear_emo().add_line(dl.mk("if you came to this town to look for yourself..."))
				dlg.add_line(dl.mk("...ha, you won't like what you'll find."))
			aval_choices.erase("me")
			await dlg.speak_choice()
		elif choice.begins_with("bye"):
			dlg.reset().set_char("mail_man")
			relationship -= exasperation
			if not mentioned_job:
				dlg.add_line(dl.mk("well, we both have work to do.").semotion(default_emo))
			else:
				dlg.clear_emo().add_line(dl.mk("i hope to see your eager face soon."))
				relationship += 1
			await dlg.speak_choice()
			break


func jobtalk() -> void:
	var dlg := DB.new().set_char("mail_man")

	var welcome := "welcome to the post office."
	if relationship < 0: dlg.set_emo("serious")
	if relationship <= -5: welcome = "...hello."
	if relationship > 2 and games_finished > 0: welcome = "ah, the newspaper boy."

	var aval_choices := ["job", "bye"]

	dlg.add_line(dl.mk(welcome))
	dlg.add_line(dl.mk("what do you need?").schoices(aval_choices))

	var choice := await dlg.speak_choice()
	if choice == "bye":
		if relationship < -2:
			return
		if relationship < 1:
			dlg.reset().set_char("mail_man").add_line(dl.mk("well, just wasting time, then."))
			await dlg.speak_choice()
			return
		relationship -= 1
		dlg.reset().set_char("mail_man")
		dlg.add_line(dl.mk("the job is waiting for you. i am sure you need it."))
		await dlg.speak_choice()
		return
	elif choice == "job":
		dlg.reset().set_char("mail_man")
		if relationship < -2:
			if hovered_over_job:
				dlg.set_emo("exasperated").add_line(dl.mk("are you going or not.").schoices(["ok", "nevermind"]))
			else:
				if games_finished < 1:
					relationship += 1
					dlg.add_line(dl.mk("...you want to take the mail delivery job?")).clear_emo()
					dlg.add_line(dl.mk("well, if you so desperately insist...."))
				dlg.add_line(dl.mk("you can go."))
				dlg.add_line(dl.mk("but if you wreck my bicycle...").semotion("exasperated"))
				dlg.add_line(dl.mk("do your best that it will not come to that.").semotion("serious").schoices(["ok", "nevermind"]))
			choice = await dlg.speak_choice()
			if choice == "ok":
				job_request.emit()
				return
			else:
				hovered_over_job = true
				dlg.reset().set_emo("exasperated").add_line(dl.mk("..."))
				await dlg.speak_choice()
				return
		if hovered_over_job:
			dlg.add_line(dl.mk("are you ready to go?").schoices(["ok", "wait"]))
		else:
			if games_finished < 1:
				relationship += 1
				dlg.clear_emo().add_line(dl.mk("interested in the job? excellent."))
				dlg.add_line(dl.mk("i will hand you a tutorial sheet in a moment..."))
				dlg.add_line(dl.mk("and then you are off on your own. good luck.").schoices(["ok", "wait"]))
			else:
				dlg.add_line(dl.mk("excellent. you can go right away.").semotion("content"))
				dlg.clear_emo().add_line(dl.mk("good luck.").schoices(["ok", "wait"]))
		choice = await dlg.speak_choice()
		if choice == "ok":
			job_request.emit()
			return
		else:
			if not hovered_over_job:
				dlg.reset().set_emo("serious")
				dlg.add_line(dl.mk("you have something you need to [color=#aaea8a]save[/color] first?"))
				dlg.add_line(dl.mk("well, go do that, then."))
				hovered_over_job = true
			else:
				return
			await dlg.speak_choice()
			return


func returntalk(results: Dictionary) -> void:
	# available in results:
	var mail_hits: int = results["mail_hits"]
	var silver_collected: int = results["silver_collected"]
	var hells_survived: int = results["hells_survived"]
	var inventory: Array = results["inventory"]
	var bike_hits: int = results["bike_hits"]
	var bike_health_proportion: float = results["bike_health_proportion"]
	var kiosks_activated: int = results["kiosks_activated"]
	var dlg := DB.new().set_char("mail_man")
	if games_finished == 1: # first
		var extras := ""
		if relationship < 0:
			dlg.set_emo("serious").add_line(dl.mk("you are back."))
			if mail_hits > 60:
				relationship += 1
				dlg.add_line(dl.mk("you did surprisingly well for your first time."))
		else:
			dlg.add_line(dl.mk("there you are."))
			if mail_hits < 30 or bike_health_proportion < 0.4:
				dlg.add_line(dl.mk("i could tell it was your first time, but..."))
				dlg.add_line(dl.mk("congratulations, still."))
			else:
				dlg.add_line(dl.mk("you did surprisingly well."))
			dlg.add_line(dl.mk("your first end on this job..."))
			if kiosks_activated == 0:
				relationship -= 1
				dlg.set_emo("serious").add_line(dl.mk("i hope next time you will be less afraid to approach me."))
				dlg.clear_emo()
				extras = "... and "
			if hells_survived > 0:
				dlg.set_emo("serious")
				dlg.add_line(dl.mk(extras + "i recommend that you actually do avoid the snails."))
				dlg.clear_emo()
				extras = "... and "
		if bike_hits == 0:
			relationship += 1
			dlg.add_line(dl.mk(extras + "you kept my bicycle in pristine condition throughout."))
			dlg.add_line(dl.mk("i like your diligence."))
			extras = "... and "
			DAT.incri("no_hit_biking_runs", 1)
	# tally
	if relationship < 0:
		dlg.set_emo("serious")
	elif relationship < 10:
		dlg.add_line(dl.mk("let me tally up your performance."))
	else:
		dlg.add_line(dl.mk("let's see how well you did, newspaper boy."))

	var payment := BattleRewards.new()

	dlg.add_line(dl.mk(str(silver_collected) + " silver gathered."))
	if DAT.get_data("mimgame_silver_maxscore", 80) < silver_collected:
		DAT.set_data("mimgame_silver_maxscore", silver_collected)
		if relationship > 0: dlg.set_emo("content")
		dlg.add_line(dl.mk("...that is the most you have gotten so far, i reckon."))
		if relationship > 0: dlg.clear_emo()

	if relationship > 0:
		if bike_health_proportion < 0.75:
			dlg.add_line(dl.mk("unfortunately, i will have to use some to repair my bicycle...").semotion("serious"))
			dlg.add_line(dl.mk("be more careful next time."))
			silver_collected = roundi(silver_collected * remap(bike_health_proportion, 0.75, 0.0, 0.75, 0.99))
	else:
		silver_collected /= 2
		if bike_health_proportion < 0.67:
			dlg.add_line(dl.mk("but my bicycle will need repairs."))
			silver_collected = 0
	payment.add(Reward.new().stype(BattleRewards.Types.SILVER).sproperty(str(silver_collected)))
	if games_finished > 1 and bike_hits == 0:
		relationship += 1
		dlg.clear_emo()
		dlg.add_line(dl.mk("you were diligent in keeping my bicycle without harm."))
		dlg.add_line(dl.mk("good.").semotion("content"))
		if relationship <= 0:
			dlg.set_emo("serious")
		payment.add(Reward.new().stype(BattleRewards.Types.SILVER).sproperty(str(30)))
		DAT.incri("no_hit_biking_runs", 1)

	dlg.add_line(dl.mk(str(mail_hits) + " mail delivered."))
	if mail_hits > 70:
		relationship += 1
		dlg.add_line(dl.mk("that is good."))
	elif mail_hits < 30:
		relationship -= 1
		dlg.add_line(dl.mk("that is just not good enough."))
		dlg.add_line(dl.mk("whose door will the people whose mail was missed..."))
		dlg.add_line(dl.mk("...come knocking to? yours? i do not think so."))
	if DAT.get_data("mimgame_mails_maxscore", 60) < mail_hits:
		DAT.set_data("mimgame_mails_maxscore", mail_hits)
		if relationship > 0: dlg.set_emo("content")
		dlg.add_line(dl.mk("...that is the most you have delivered so far, i reckon."))
		if relationship > 0: dlg.clear_emo()
	var mailxp := mail_hits * 0.25
	mailxp *= pow(hells_survived + 1, 2.3)
	payment.add(Reward.new().stype(BattleRewards.Types.EXP).sproperty(str(roundi(mailxp))))

	if relationship > 0:
		for i in inventory:
			payment.add(Reward.new().stype(BattleRewards.Types.ITEM).sproperty(str(i)))

	if games_finished == 1:
		payment.add(Reward.new().stype(BattleRewards.Types.ITEM).sproperty("bike_helmet").sunique(true))

	await dlg.speak_choice()
	payment.grant()
	await payment.granted

	if relationship > 0:
		dlg.reset().set_char("mail_man")
		dlg.add_line(dl.mk("we will make a proper newspaper boy out of you yet."))
		await dlg.speak_choice()
