class_name DebugConsole extends Control

enum DataCommands {SET, INCRI,}

var current_command: String
var last_command: String
var history: PackedStringArray
var down_history: PackedStringArray
@onready var clog: RichTextLabel = $Log
@onready var line: LineEdit = $Line


func _process(_delta: float) -> void:
	line.grab_focus()


func _on_text_submitted(new_text: String) -> void:
	last_command = current_command
	current_command = new_text
	history.append(last_command)
	line.clear()
	parse_command()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		DAT.free_player("debug_console")
		queue_free()
	# these dont work
	if event.is_action_pressed("move_up"):
		print("up")
		line.text = history[0]
		down_history.append(history[0])
		history.remove_at(0)
	elif event.is_action_pressed("ui_down"):
		line.text = down_history[0]
		history.append(down_history[0])
		down_history.remove_at(0)
	get_viewport().set_input_as_handled()


func parse_command() -> void:
	if current_command == "":
		output("")
		return
	var args := current_command.split(" ", false)
	if args.size() < 1:
		output("type a command", true)
		return
	var cmd := args[0]
	args.remove_at(0)

	match StringName(cmd):
		&"greg":
			output("gregged.")
		&"bset":
			battle_set(args)
		&"bend":
			battle_end(args)
		&"help":
			output("available commands are: greg,bset,bend,help,ex,clear,history,vfx,printdata,xp,lvup,dial,gitem,gspirit,gsilver,reload,instakill,clearinv,goto,win,seconds,7\ntype command without args to get help")
		&"ex":
			ex(args)
		&"clear":
			output("\n\n\n\n\n\n\n\n\n\n")
		&"history":
			print(history)
		&"vfx":
			vfx(args)
		&"printdata":
			print(DAT.A)
		&"setdata":
			setdata(args)
		&"xp":
			xp(args)
		&"lvup":
			lvup(args)
		&"hurt":
			hurt(args)
		&"dial":
			if args.size() < 1:
				output("need dialogue key", true)
				return
			if not args[0] in SOL.dialogue_box.dialogues_dict.keys():
				output("key doesn't exist", true)
				return
			SOL.dialogue(args[0])
		&"gitem":
			give_item(args)
		&"gspirit":
			give_spirit(args)
		&"gsilver":
			give_silver(args)
		&"goto":
			goto(args)
		&"reload":
			DAT.save_to_data()
			LTS.gate_id = LTS.GATE_LOADING
			if args.is_empty():
				DAT.load_data_from_dict(DAT.A, true)
			else:
				LTS.level_transition(LTS.ROOM_SCENE_PATH % DAT.get_data("current_room", "test_room"))
		&"instakill":
			instakill()
			output("greg's attack stack ridiculous now")
		&"clearinv":
			ResMan.get_character("greg").inventory.clear()
			output("inventory cleared")
		&"addperk":
			add_perk(args)
		&"win":
			win()
		&"csm":
			get_window().content_scale_mode = (Window.CONTENT_SCALE_MODE_VIEWPORT
					if get_window().content_scale_mode == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
					else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS)
		&"seconds":
			seconds(args)
		&"7":
			output("7")
		_:
			output("no such command", true)


func output(s: String, error := false) -> void:
	if error: s = "[color=#ff8888]%s[/color]" % s
	clog.append_text("\n" + s)


func battle_set(args: PackedStringArray) -> void:
	var cs: Node = LTS.get_current_scene()
	if not cs.scene_file_path == "res://scenes/tech/scn_battle.tscn":
		output("needs to be used in battle", true)
		return
	if args.size() < 1:
		output("usage: bset team nr var value")
		return
	if args.size() < 4:
		output("missing args", true)
		return
	var team := 0
	if args[0].is_valid_int() and int(args[0]) in range(0, 2):
		team = int(args[0])
	else:
		output("argument 1 should be 0 or 1", true)
		return
	var get_team: Array = cs.enemies if team == 1 else cs.party
	var nr := 0
	if args[1].is_valid_int() and int(args[1]) in range(0, get_team.size()):
		nr = int(args[1])
	else:
		output("argument 2 should be actor index of team", true)
	var variant := args[2]
	var value := args[3]
	get_team[nr].set_indexed(variant, value)
	output("set %s %s property %s to %s" % ["enemy" if team == 1 else "party member", str(get_team[nr]), variant, value])


func battle_end(_args: PackedStringArray) -> void:
	var cs: Node = LTS.get_current_scene()
	if not cs.scene_file_path == "res://scenes/tech/scn_battle.tscn":
		output("needs to be used in battle", true)
		return
	(cs).check_end(true)


func setdata(args: PackedStringArray) -> void:
	if args.size() < 1:
		output("usage: setdata key value")
		return
	if args.size() != 2:
		output("needs two arguments", true)
		return
	var key := args[0]
	var value: Variant = args[1]
	_data_change(DataCommands.SET, key, value)


func _data_change(type: DataCommands, key: StringName, value: Variant) -> void:
	value = Math.toexp(value)
	match type:
		DataCommands.SET:
			DAT.set_data(key, value)
			output("set data %s to %s" % [key, value])
		DataCommands.INCRI:
			DAT.incri(key, value)
			output("incremented %s to %s" % [key, DAT.get_data(key)])


func ex(args: PackedStringArray) -> void:
	if args.size() < 1:
		output("usage: ex gdscript_expression")
		return
	if args.size() > 1:
		output("needs to have one argument", true)
		return
	var expr := Expression.new()
	var error := expr.parse(args[0])
	if error != OK:
		output("error in expression:", true)
		output(expr.get_error_text(), true)
		return
	var result: Variant = expr.execute([], self)
	if not expr.has_execute_failed():
		output(str(result))
	else:
		output("execution failed:", true)
		output(expr.get_error_text(), true)


func xp(args: PackedStringArray) -> void:
	if args.size() < 1:
		output("usage: xp charname amount")
		return
	var charname := args[0]
	var chara := ResMan.get_character(charname)
	var amount := int(args[1]) if args.size() == 2 else 0
	if not LTS.get_current_scene().name == "Battle":
		if amount != 0:
			chara.add_experience(amount)
			output("gave %s exp to %s" % [amount, charname])
			return
		output("char %s has %s/%s exp" %
				[amount, chara.experience, chara.xp2lvl(chara.level + 1)])
		return
	if charname != &"greg":
		return
	var battle = LTS.get_current_scene()
	chara = battle.party[0].character
	if amount != 0:
		chara.add_experience(amount)
		return

	output("char %s has %s/%s exp" %
			[amount, chara.experience, chara.xp2lvl(chara.level + 1)])


func lvup(args: PackedStringArray) -> void:
	if args.size() < 1:
		output("usage: lvup charname amount")
		return
	if args.size() != 2:
		output("need 2 arguments", true)
		return
	var charname := args[0]
	var amount := int(args[1])
	ResMan.get_character(charname).level_up(amount)
	output("leveled %s to %s" % [charname, amount + 1])


func hurt(args: PackedStringArray) -> void:
	if args.size() < 1:
		output("usage: lvup charname amount")
		return
	if args.size() != 2:
		output("need 2 arguments", true)
		return
	var charname := args[0]
	var amount := int(args[1])
	ResMan.get_character(charname).health -= amount
	output("hurt %s by %s" % [charname, amount])


func vfx(args: PackedStringArray) -> void:
	if args.size() < 1:
		output("usage: vfx name/'list' posx posy")
		return
	var nomen := ""
	nomen = args[0]
	if nomen == "list":
		output("printing files in vfx folder")
		print(DIR.get_dir_contents("res://scenes/vfx"))
		return
	if not ResourceLoader.exists("res://scenes/vfx/scn_vfx_%s.tscn" % nomen):
		output("faulty effect name", true)
		return
	var posx := 0.0
	var posy := 0.0
	if args.size() >= 3:
		if args[1].is_valid_float() and args[2].is_valid_float():
			posx = float(args[1]); posy = float(args[2])
		else:
			output("position arguments faulty", true)
	SOL.vfx(nomen, Vector2(posx, posy))


func give_item(args: PackedStringArray) -> void:
	if args.size() < 1:
		output("usage: gitem itemname")
		return
	var itemname := args[0]
	DAT.grant_item(itemname)
	output("gave item " + args[0])


func give_silver(args: PackedStringArray) -> void:
	if args.size() < 1:
		output("usage: gsilver amount")
		return
	var silver := Math.toexp(args[0]) as int
	DAT.grant_silver(silver)
	output("gave " + args[0] + " silver")


func give_spirit(args: PackedStringArray) -> void:
	if args.size() < 1:
		output("usage: gspirit spiritname")
		return
	var spiritname := args[0]
	DAT.grant_spirit(spiritname)
	output("gave spirit " + args[0])


func instakill() -> void:
	ResMan.get_character("greg").attack = 2138123812 # because
	if LTS.get_current_scene().name == "Battle":
		LTS.get_current_scene().party[0].character.attack = 2138123812


func add_perk(args: PackedStringArray) -> void:
	if args.size() < 1:
		output("usage: addperk key value")
		return
	if args.size() < 2:
		output("need 2 ars", true)
		return
	var questing := DAT.get_data("forest_questing") as ForestQuesting
	if not is_instance_valid(questing):
		output("must be in forest", true)
		return
	questing.add_perk({args[0]: Math.toexp(args[1])})
	output("perk added")


func goto(args: PackedStringArray) -> void:
	if args.size() < 1:
		output("usage: goto room")
		return
	var room: String = LTS.ROOM_SCENE_PATH % args[0]
	if not ResourceLoader.exists(room):
		output("room %s doesn't exist" % args[0], true)
		return
	LTS.level_transition(room)
	output("going to " + args[0])


func win() -> void:
	var battle = LTS.get_current_scene()
	if not battle.name == "Battle":
		output("not in battle", true)
		return
	battle.check_end(true)


func seconds(args: PackedStringArray) -> void:
	if args.is_empty():
		output("seconds: " + str(DAT.seconds))
		return
	var secs: Variant = Math.toexp(args[0])
	if not secs is int:
		output("not a number", true)
		return
	DAT.seconds = secs
	output("set secs to " + args[0])

