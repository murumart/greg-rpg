extends Node2D

@onready var mus_bar_counter: MusBarCounter = $MusBarCounter
@onready var pulse_d: Sprite2D = $Greg/Camera/PulseD
@onready var greg: PlayerOverworld = $Greg
@onready var music: AudioStreamPlayer = $AudioStreamPlayer
@onready var grand: OverworldCharacter = $Decor/Grand


func _ready() -> void:
	#SOL.dialogue_box.modulate = Color(0.851, 0.702, 0.478, 1.0)
	mus_bar_counter.new_beat.connect(func() -> void:
		var tw := create_tween().set_trans(Tween.TRANS_BOUNCE)
		tw.set_ease(Tween.EASE_OUT).tween_property(pulse_d, ^"scale", Vector2.ONE, 0.4)
		tw.set_ease(Tween.EASE_IN).tween_property(pulse_d, ^"scale", Vector2.ONE * 0.98, 0.02)
	)
	SOL.fade_screen(Color.WHITE, Color.TRANSPARENT, 2.0, {kill_rects = true})
	grand.inspected.connect(_g_statue_interact)
	for n: Sprite2D in get_tree().get_nodes_in_group("stonepeople_sprites"):
		n.region_rect.position.x = randi_range(0, 3) * 16
		n.region_rect.position.y = randi_range(0, 3) * 16
	for n: OverworldCharacter in get_tree().get_nodes_in_group("stonepeople"):
		n.inspected.connect(func() -> void:
			var dlg := DialogueBuilder.new().set_char("column_talk")
			dlg.al(dlg.SGD + "[center]" + [
				"remembering",
				"storing",
				"saving",
				"waiting",
				"eagerly",
				"reminiscing",
				"reproduction",
				"copy",
				"right where we left off",
				"ready",
			].pick_random())
			dlg.speak_choice()
		)


func _g_statue_interact() -> void:
	var dlg := DialogueBuilder.new()



func _process(delta: float) -> void:
	var dist := 1275 - greg.position.x
	if dist < 300:
		music.volume_linear = remap(dist, 300, 0, 1.0, 0.05)
