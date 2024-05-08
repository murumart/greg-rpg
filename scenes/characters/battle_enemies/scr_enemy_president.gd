extends BattleEnemy

const BackgroundType := preload("res://scenes/battle_backgrounds/scr_president_background.gd")

var background: BackgroundType

var progress := 0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	if LTS.get_current_scene().name == "Battle":
		background = LTS.get_current_scene().background_container.get_child(0)
		if background.skip_intro:
			return
	var tw := create_tween()
	tw.tween_property(self, "global_position:y", 190.0, 7.0).from(189.0)
	tw.tween_property(self, "global_position:y", 1.0, 14)
	tw.parallel().tween_property(self, "modulate", Color.WHITE, 30
			).from(Color.BLACK)


func hurt(amount: float, gender: int) -> void:
	amount = _progress_check(amount)
	super(amount, gender)


func _progress_check(damage: float) -> float:
	if (character.health - damage) / character.max_health < 0.5 and progress == 0:
		progress = 1
		SOL.dialogue("president_50")
		damage += (character.health - damage) - character.max_health * 0.7
	elif (character.health - damage) / character.max_health < 0.33 and progress == 1:
		SOL.dialogue("president_33")
		damage += (character.health - damage) - character.max_health * 0.33
		if not is_instance_valid(background):
			return damage
		SOL.dialogue_closed.connect(func():
			background.hide_ui()
			background.lighthouse_zoom_out()
			SOL.dialogue_open = true
			var tw := create_tween()
			tw.tween_property(sprite, "scale", Vector2(0.2, 0.2), 2.0)
			tw.parallel().tween_property(
					SND.current_song_player, "pitch_scale",
					2.0, 2.0)
			SOL.fade_screen(Color.TRANSPARENT, Color.WHITE, 1.9)
			tw.finished.connect(func():
				SND.play_song("", 2992)
				SND.play_song("dishout", 0.2)
				var t := create_tween()
				t.tween_property(
					SND.current_song_player,
					"pitch_scale",
					1.0,
					6.0
				).from(0.5)
				SOL.fade_screen(Color.WHITE, Color.TRANSPARENT, 6.0)
			)
		, CONNECT_ONE_SHOT)
	return damage
