extends Node2D

@onready var guy := $Guy as OverworldCharacter
@onready var mail_man := $"../MailMan" as OverworldCharacter
@onready var uguy_pos: Marker2D = $UguyPos
@onready var uguy_pos_2: Marker2D = $UguyPos2
@onready var greg_start_pos := $"../../Areas/RoomGate/SpawnPoint"
@onready var greg: PlayerOverworld = $"../../Greg"
@onready var camera: Camera2D = $"../../Greg/Camera"
@onready var canvas_modulate: CanvasModulate = $"../../Greg/Camera/CanvasModulate"


func _ready() -> void:
	pass


func start() -> void:
	DAT.capture_player("cutscene")
	guy.show()
	SOL.dialogue_box.started_speaking.connect(shuffle)
	greg.global_position = greg_start_pos.global_position - Vector2(0, 11)
	greg.animate("walk_up")
	mail_man.speed = 0
	await create_tween().tween_interval(1.5).finished
	SOL.dialogue("pocutscene_1")
	SOL.dialogue_closed.connect(func():
		SOL.dialogue_box.started_speaking.disconnect(shuffle)
		await create_tween().tween_interval(0.5).finished
		guy.move_to(uguy_pos.global_position)
		var tw := create_tween()
		greg.animate("walk_up", true)
		tw.tween_property(greg, "global_position", uguy_pos_2.global_position, 1)
		tw.parallel().tween_method(func(_a: float):
			guy.direct_walking_animation(greg.global_position - guy.global_position)
		, 0.0, 1.0, 1.0)
		tw.tween_callback(greg.animate.bind("walk_left"))
		tw.tween_callback(guy.direct_walking_animation.bind(Vector2.RIGHT))
		tw.tween_callback(func(): SOL.dialogue("pocutscene_2"))
		SOL.dialogue_box.started_speaking.connect(look)
		SOL.dialogue_closed.connect(func():
			tw = create_tween().set_trans(Tween.TRANS_CUBIC)
			var old_player := SND.current_song_player
			SND.play_song("", 0.3)
			tw.tween_property(canvas_modulate, "color",
					Color(0.52941179275513, 0.21176470816135, 0.44313725829124),
					4.0)
			tw.parallel().tween_property(camera, "zoom", Vector2(2.0, 2.0), 4.0)
			tw.parallel().tween_method(func(p: float):
				if is_instance_valid(old_player):
					old_player.pitch_scale = p
			, 1.0, 0.65, 3.0)
			await tw.finished
			SOL.dialogue("pocutscene_3")
			SOL.dialogue_box.started_speaking.connect(linebased_3)
			SOL.dialogue_closed.connect(func():
				guy.time_moved_limit = 3000
				guy.speed *= 2
				guy.move_to(greg_start_pos.global_position + Vector2(0, 5))
				greg.animate("walk_down")
				guy.target_reached.connect(func():
					cleanup()
					SOL.dialogue_box.started_speaking.disconnect(linebased_3)
					SOL.dialogue_box.started_speaking.disconnect(look)
					await create_tween().tween_interval(1.0).finished
					SOL.dialogue("pocutscene_4")
					greg.animate("walk_up")
					SOL.dialogue_closed.connect(func():
						mail_man.speed = 3000
						DAT.free_player("cutscene")
						DAT.set_data("witnessed_ushanka_guy_cutscene", true)
					, CONNECT_ONE_SHOT)
				, CONNECT_ONE_SHOT)
			, CONNECT_ONE_SHOT)
		, CONNECT_ONE_SHOT)
	, CONNECT_ONE_SHOT)


func cleanup() -> void:
	guy.hide()
	guy.global_position.x += 1000
	guy.set_physics_process(false)


func consequences() -> void:
	SND.call_deferred("play_song", "")
	DAT.set_data("mail_man_dead", true)
	DAT.set_data("uguy_following", false)
	mail_man.queue_free()
	guy.global_position = Vector2(-50, 0)
	guy.default_lines.clear()
	guy.show()
	guy.default_lines.append("uguy_mail_house_no_vampire")
	guy.default_lines.append("uguy_mail_house_no_vampire_2")


func shuffle(line: int) -> void:
	if SOL.dialogue_box.loaded_dialogue_line.character == "mail_man":
		look(line)
		return
	if line % 2 == 0:
		guy.move_to(uguy_pos.global_position)
	else:
		guy.move_to(uguy_pos_2.global_position)


func look(_line: int) -> void:
	if SOL.dialogue_box.loaded_dialogue_line.character == "mail_man":
		guy.direct_walking_animation(Vector2.UP)
		return
	guy.direct_walking_animation(Vector2.RIGHT)


func linebased_3(line: int) -> void:
	if line == 10:
		canvas_modulate.color = Color.WHITE
	if line == 11:
		create_tween().tween_property(camera, "zoom", Vector2.ONE, 0.5)
	if line == 14:
		SND.play_song("mail_man")
