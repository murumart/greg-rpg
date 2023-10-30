class_name DebugConsole extends Control


var current_command : String
var last_command : String
var history : PackedStringArray
var down_history : PackedStringArray
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
	if current_command == "": output(""); return
	var args := current_command.split(" ", false)
	var cmd := args[0]
	args.remove_at(0)
	
	match StringName(cmd):
		&"greg":
			output("gregged.")
		&"bset":
			battle_set(args)
		&"help":
			output("available commands are: greg,bset,help,ex,clear,history,vfx,7\ntype command without args to get help")
		&"ex":
			ex(args)
		&"clear":
			output("\n\n\n\n\n\n\n\n\n\n")
		&"history":
			print(history)
		&"vfx":
			vfx(args)
		&"7":
			output("7")
		_:
			output("no such command", true)
		

func output(s: String, error := false) -> void:
	if error: s = "[color=#ff8888]%s[/color]" % s
	clog.append_text("\n" + s)


func battle_set(args: PackedStringArray) -> void:
	var cs := DAT.get_current_scene()
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
	get_team[nr].set(variant, value)
	output("set %s %s property %s to %s" % ["enemy" if team == 1 else "party member", str(get_team[nr]), variant, value])


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
	var result : Variant = expr.execute([], self)
	if not expr.has_execute_failed():
		output(str(result))
	else:
		output("execution failed:", true)
		output(expr.get_error_text(), true)


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
