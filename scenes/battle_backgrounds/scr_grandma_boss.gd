extends "res://scenes/battle_backgrounds/scr_battle_background.gd"

@onready var sprite: Sprite2D = $Sprite2D
@onready var rts: RichTextLabel = $RichTextLabel

const WORDS: Array[String] = ["flowers", "mdp", "greg", "rpg", "rpg", "green", "os", "oversee", "mdp", "mdp", "florist", "murumart"]
var _text := ""

func _ready() -> void:
	var t := ""
	for i in 50:
		t += WORDS.pick_random()
	_text = t


var _timer := 0.0

func _process(delta: float) -> void:
	_timer -= delta
	var sp := 0.0
	var spb := 0.145
	var song := SND.current_song_player
	if not is_instance_valid(song):
		return
	var playback_pos := song.get_playback_position()
	if playback_pos >= 55.817:
		sp = 1.0
		spb = 1.415
		if _timer <= 0:
			_text = WORDS.pick_random().repeat(100)
			_timer = randf_range(0.1, 0.4)
	else:
		var word: String = WORDS.pick_random()
		var t := _text
		var pos := randi() % (t.length() - word.length())
		t = t.erase(pos, word.length())
		t = t.insert(pos, word)
		_text = t

	rts.text = _text
	sprite.material["shader_parameter/wow"] = sp
	rts.material["shader_parameter/bmul"] = spb
	rts.material["shader_parameter/rmul"] = spb * 2.0
