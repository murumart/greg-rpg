extends Node2D

@onready var interior_tiles: TileMap = $"../InteriorTiles"
@onready var grandma := $"../InteriorTiles/Grandma"
@onready var greg_pos: Node2D = $GregPos
@onready var greg: PlayerOverworld = $"../Greg"
@onready var camera: Camera2D = $"../Greg/Camera"
@onready var greg_picture: TextureRect = $Darkness/Greg
@onready var anu_picture: TextureRect = $Darkness/Anu
@onready var darkness: ColorRect = $Darkness


func _ready() -> void:
	hide()


func play() -> void:
	show()
	$Mirror.show()
	remove_child(darkness)
	SOL.add_ui_child(darkness)
	darkness.modulate.a = 0.0
	DAT.capture_player("cutscene")
	interior_tiles.set_layer_enabled(1, false)
	grandma.queue_free()
	greg.global_position = greg_pos.global_position
	greg.animate("walk_up")
	camera.global_position.y -= 20
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_callback(func():
		greg.animate("walk_up", true)
	)
	tw.tween_property(greg, "global_position:y", greg.global_position.y - 35, 3.0)
	tw.tween_callback(func():
		greg.animate("walk_up")
	)
	tw.tween_interval(0.5)
	tw.tween_callback(greg_picture.show)
	tw.tween_property(darkness, "modulate:a", 1.0, 0.5)
	tw.parallel().tween_property(greg_picture, "modulate:a", 1.0, 4.0).from(0.0)
	tw.tween_callback(anu_picture.show)
	tw.tween_property(anu_picture, "modulate:a", 0.8, 4.0).from(0.0)
	tw.tween_property(greg_picture, "modulate:a", 0.0, 8.0)
	if is_instance_valid(SND.current_song_player):
		tw.parallel().tween_property(SND.current_song_player, "pitch_scale", 0.1, 8.0)
	tw.parallel().tween_property(anu_picture.material, "shader_parameter/mix_amount",
			11.0, 4.0).set_delay(4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		SND.play_song("")
		LTS.level_transition("res://scenes/cutscene/scn_evilend.tscn")
	)
	
