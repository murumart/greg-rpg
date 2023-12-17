extends Node2D

var metal := ["metal", "kitchen utensils", "gardening tools", "railroad tracks", "rebar", "vehicles", "mirrors", "statues", "girders", "lamp posts", "weapons", "money", "construction tools", "soup cans", "pens", "knives", "coins", "silver", "jewellery", "brooches", "pins", "rings"]
var heroes: int

@onready var textbox: TextBox = $Textbox
@onready var spirit_masters := $Images/SpiritMasterDisplay

@onready var imgs := [$Images/Image1, $Images/Image2]
var texs := {
	"anu": preload("res://sprites/cutscene/warstory/spr_anu.png"),
	"spoon": preload("res://sprites/cutscene/warstory/spr_spoon.png"),
	"spoob": preload("res://sprites/cutscene/warstory/spr_spoob.png"),
	"political": preload("res://sprites/cutscene/warstory/spr_me_when_i_get_political.png"),
	"map": preload("res://sprites/cutscene/warstory/spr_map.png"),
	"statue": preload("res://sprites/cutscene/warstory/spr_statue.png"),
	"statue2": preload("res://sprites/cutscene/warstory/spr_statue_close.png"),
	"cursed": preload("res://sprites/cutscene/warstory/spr_cursed.png"),
	"hero": preload("res://sprites/cutscene/warstory/spr_hero.png"),
	"redback": preload("res://sprites/cutscene/warstory/spr_heroes.png"),
	"spirit_master": preload("res://sprites/cutscene/warstory/spr_spirit_master.png"),
	"grab": preload("res://sprites/cutscene/warstory/spr_grab.png"),
	"2remain": preload("res://sprites/cutscene/warstory/spr_2remain.png"),
	"sitting": preload("res://sprites/cutscene/warstory/spr_me_when_im_sitting.png"),
	"spirits": preload("res://sprites/cutscene/warstory/spr_spirits.png"),
	"liberation": preload("res://sprites/cutscene/warstory/spr_liberation.png"),
	"nostatue": preload("res://sprites/cutscene/warstory/spr_nostatue.png"),
}


func _ready() -> void:
	SND.play_song("warstory", 1.0, {"start_volume": 1.0, "play_from_beginning": true})
	next_bar(0)
	var rng := RandomNumberGenerator.new()
	rng.seed = ceili(Math.süsarv() * 1000)
	heroes = rng.randi_range(4, 8)
	DIR.sej(2003, 1)


var talking_about_metal := false
func _process(_delta: float) -> void:
	if talking_about_metal:
		if randf() < 0.04: talk_about_metal()


func next_bar(bar: int) -> void:
	if bar == 18:
		$BarCounter.flbar += 0.6
	match bar:
		0:
			talk("it happened twenty years ago now.")
		1:
			talk("a man discovered within himself spirit mastery.")
			imgs[0].texture = texs["anu"]
			fadein(imgs[0])
		2:
			talk("[color=#aaaaaa]anu armu[/color] could make metal conform to his will.", 14)
			talking_about_metal = true
			imgs[0].texture = texs["spoon"]
			imgs[1].texture = texs["spoob"]
		3:
			talk("he decided to make this power serve his ambition.")
			fadeout(imgs[0])
			fadein(imgs[1])
		4:
			talk("first, he rose through the ranks politically.")
			talking_about_metal = false
			fadeout(imgs[1])
		5:
			talk("(by assassinating his opponents with their kitchen tools.)", 12)
			imgs[0].texture = texs["political"]
			fadein(imgs[0])
		6:
			talk("within a week, the nation of koond was under his rule.", 11)
			fadeout(imgs[0])
			imgs[1].texture = texs["map"]
			imgs[1].position.y = 72
			fadein(imgs[1])
			move(imgs[1], Vector2(80, 40), 8.0)
		7:
			talk("anu's ambition, however, extended beyond his homeland.", 11)
		8:
			talk("so one day, statues, buildings, all of metal")
			imgs[0].position.y = 36
			imgs[0].texture = texs["statue"]
			fadeout(imgs[1])
			fadein(imgs[0])
			move(imgs[0], Vector2(80, 72), 4.0)
		9:
			talk("stood down and greeted us.")
			imgs[1].position.y = 56
			imgs[1].texture = texs["statue2"]
			fadein(imgs[1])
			fadeout(imgs[0])
		10:
			talk("cursed iron maiming, destroying, now worldwide.")
			imgs[0].texture = texs["cursed"]
			imgs[0].position.x = 195
			imgs[0].position.y = 56
			fadeout(imgs[1])
			fadein(imgs[0])
			move(imgs[0], Vector2(0, 56), 14.0)
		11:
			talk("around the globe, everyone - powerless to stop it.", 11)
		12:
			talk("i mean, how could we, with our guns and blades?", 11)
		13:
			talk("this was the end of the world...")
			fadeout(imgs[0])
		14:
			talk("but it is in dire times like these")
			imgs[0].position.x = 80
			imgs[1].position.x = 80
			imgs[1].texture = texs["hero"]
			imgs[0].texture = texs["redback"]
			fadein(imgs[1])
			for i in heroes:
				var sprit := Sprite2D.new()
				sprit.texture = texs["spirit_master"]
				spirit_masters.add_child(sprit)
			spirit_masters.arrange()
		15:
			talk("when heroes arise.")
			spirit_masters.show()
			fadein(imgs[0], 0.00001)
			fadeout(imgs[1])
		16:
			talk("%s powerful spirit masters banded together" % heroes)
			imgs[1].texture = texs["redback"]
		17:
			talk("to end anu's reign of terror over the world.")
			fadein(imgs[1])
		18:
			talk("")
			imgs[1].texture = texs["grab"]
			imgs[0].texture = texs["2remain"]
		19:
			talk("carrying no metal, 2 of them made it")
			fadeout(imgs[1], 0.0001)
			spirit_masters.hide()
		20:
			talk("to his lair, unguarded by humans")
			imgs[1].texture = texs["sitting"]
		21:
			talk("and found him vulnerable.")
			fadein(imgs[1])
		22:
			talk("his own power allowed him to die there", 11)
			imgs[0].texture = texs["spirits"]
		23:
			talk("for bloodshed and suffering are what spirits crave.", 12)
			fadeout(imgs[1])
		24:
			talk("with his death, all metal was unbound from the curse", 11)
			fadeout(imgs[0])
			imgs[1].texture = texs["liberation"]
		25:
			talk("[center]and the world could breathe free once more.[/center]", 12)
			fadein(imgs[1])
		26:
			talk("")
			fadeout(imgs[1], 0.0001)
			fadeout(imgs[0], 0.0001)
			imgs[0].texture = texs["nostatue"]
		27:
			talk("it has been 20 years since the horror ended")
			imgs[0].position.y = 36
			move(imgs[0], Vector2(80, 72), 4.0)
			fadein(imgs[0])
		28:
			talk("and people are starting to forget, already.")
		29:
			talk("")
		30:
			fadeout(imgs[0])
		31:
			LTS.gate_id = LTS.GATE_EXIT_CUTSCENE
			LTS.level_transition(LTS.ROOM_SCENE_PATH % DAT.get_data("current_room", "test_room"))


func talk(w: String, speeddiv := 10.0) -> void:
	speeddiv += 4
	textbox.text = w
	textbox.speak_text({speed = w.length() / speeddiv})


func talk_about_metal() -> void:
	var text := SOL.vfx("damage_number",
	Vector2(
		randf_range(0, 160),
		randf_range(32, 80)),
	{"text": metal.pick_random(),
	"color": Color(0.5, 0.35, 0.1),
	"parent": $Images,
	"z_index": 0})
	text.gravity = 30


func fadein(what: Node2D, dur := 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(what, "self_modulate:a", 1.0, dur)


func fadeout(what: Node2D, dur := 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(what, "self_modulate:a", 0.0, dur)


func move(what: Node2D, where: Vector2, dur := 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(what, "position", where, dur)

