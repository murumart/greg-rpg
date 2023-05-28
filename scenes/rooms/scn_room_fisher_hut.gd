extends Room

var fish_lines := []
var line_progress_1 := 0
var line_progress_2 := 0

var fish_1 := []
var fish_2 := []

const FISH_LINE := "fish_fact_%s"


func _ready() -> void:
	super._ready()
	if not DAT.get_data("fish_warning_given", false):
		SOL.dialogue("fisherman_in_hut_warning")
		DAT.set_data("fish_warning_given", true)
	
	var i := 0
	while FISH_LINE % (i + 1) in SOL.dialogue_box.dialogues_dict.keys():
		fish_lines.append(FISH_LINE % (i + 1))
		i += 1
	for j in fish_lines.size():
		if j % 2 == 0:
			fish_1.append(fish_lines[j])
		else:
			fish_2.append(fish_lines[j])
	var rand := RandomNumberGenerator.new()
	rand.seed = roundi(DAT.get_data("nr", 0.0) * 100)
	fish_1 = Math.determ_shuffle(fish_1, rand)
	fish_2 = Math.determ_shuffle(fish_2, rand)


func _on_fisherman_interacted(which: int) -> void:
	var r := ["garbage", fish_1, fish_2]
	var line_progress : int = get("line_progress_%s" % (which))
	if line_progress < r[which].size():
		SOL.dialogue(r[which][line_progress])
		set("line_progress_%s" % which, line_progress + 1)
	else:
		SOL.dialogue(FISH_LINE % "end")


