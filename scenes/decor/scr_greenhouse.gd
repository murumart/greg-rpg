extends Node2D

# greenhouses that function as healing locations on the map

var zoom := 1.0

@export var grows_in_seconds := 600

var player : PlayerOverworld

var previous_song_key := ""

@export var has_vegetables := true


func _ready() -> void:
	set_physics_process(false)
	set_vegetables(DAT.get_data(get_save_key("has_vegetables"), has_vegetables))
	check_vegetables_regrown()


func _on_inside_area_body_entered(body: PlayerOverworld) -> void:
	player = body
	cam_zoom(Vector2(2, 2), 1)
	set_physics_process(true)
	SND.play_song("greenhouse", 1.0, {play_from_beginning = true})
	previous_song_key = SND.previously_played_song_key


func _on_inside_area_body_exited(_body: PlayerOverworld) -> void:
	cam_zoom(Vector2(1, 1), 1)
	set_physics_process(false)
	zoom = 1.0
	SND.play_song(previous_song_key)


func cam_zoom(to: Vector2, time: float) -> void:
	var tw := create_tween()
	var camera := player.find_child("Camera") as Camera2D
	tw.tween_property(camera, "zoom", to, time)


func _physics_process(delta: float) -> void:
	zoom = move_toward(zoom, 2.0, delta)
	if zoom >= 2.0:
		pleasant()


# why is it named that.
# this runs when you enter the greenhouse and wait
func pleasant() -> void:
	DAT.capture_player("greenhouse")
	set_physics_process(false)
	SOL.dialogue_box.adjust("greenhouse", 1, "choices", PackedStringArray(["eat", "sleep"]))
	if not has_vegetables:
		SOL.dialogue_box.adjust("greenhouse", 1, "choices", PackedStringArray(["sleep"]))
	SOL.dialogue("greenhouse")
	await SOL.dialogue_closed
	cam_zoom(Vector2(8, 8), 1)
	SOL.fade_screen(Color.TRANSPARENT, Color.WHITE)
	await get_tree().create_timer(1.1).timeout
	SOL.fade_screen(Color.WHITE, Color.TRANSPARENT)
	DAT.free_player("greenhouse")
	cam_zoom(Vector2(2, 2), 1)
	SND.play_song("")
	if SOL.dialogue_choice == "eat":
		for c in DAT.get_data("party", ["greg"]):
			DAT.get_character(c).fully_heal()
		DAT.set_data(get_save_key("eats"), DAT.get_data(get_save_key("eats"), 0) + 1)
		SND.play_sound(preload("res://sounds/greenhouse_heal_big.ogg"))
		if DAT.get_data("party", ["greg"]).size() > 1:
			SOL.dialogue("greenhouse_heal_party_big")
		else:
			SOL.dialogue("greenhouse_heal_greg_big")
			set_vegetables(false)
			DAT.set_data(get_save_key("vegs_eaten_second"), DAT.seconds)
			DAT.incri("greenhouses_eaten", 1)
	else:
		for c in DAT.get_data("party", ["greg"]):
			DAT.get_character(c).mostly_heal()
		DAT.set_data(get_save_key("sleeps"), DAT.get_data(get_save_key("sleeps"), 0) + 1)
		SND.play_sound(preload("res://sounds/greenhouse_heal.ogg"))
		if DAT.get_data("party", ["greg"]).size() > 1:
			SOL.dialogue("greenhouse_heal_party_small")
		else:
			SOL.dialogue("greenhouse_heal_greg_small")
		DAT.incri("greenhouses_slept", 1)


func set_vegetables(to: bool) -> void:
	has_vegetables = to
	$SprVegetables.visible = to
	DAT.set_data(get_save_key("has_vegetables"), to)


func get_save_key(key: String) -> String:
	return StringName(
		str("greenhouse_", name, "_in_",
		LTS.get_current_scene().name.to_snake_case(), "_", key))


# the second on which vegs were eaten is saved
# and then later compared to the current second.
func check_vegetables_regrown() -> void:
	$SprVegetables.visible = has_vegetables
	if DAT.seconds - DAT.get_data(
			get_save_key("vegs_eaten_second"), 0) >= grows_in_seconds:
		set_vegetables(true)


func _on_update_timer_timeout() -> void:
	check_vegetables_regrown()
