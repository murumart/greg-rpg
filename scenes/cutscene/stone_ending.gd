extends Node2D

@onready var white: ColorRect = $White
@onready var stone_people: Node2D = $StonePeople
@onready var camera: Camera2D = $Camera
@onready var end_credits := $EndCredits


func _ready() -> void:
	remove_child(end_credits)
	for i in 300:
		var sp := Sprite2D.new()
		sp.texture = preload("res://sprites/characters/overworld/spr_stonepeople.png")
		while sp.position.distance_squared_to(Vector2.ZERO) < 10_000:
			sp.position.x = randf_range(-1000, 1000)
			sp.position.y = randf_range(-1000, 1000)
		sp.region_enabled = true
		sp.region_rect.size = Vector2(16, 16)
		sp.region_rect.position.x = randi_range(0, 3) * 16
		sp.region_rect.position.y = randi_range(0, 3) * 16
		stone_people.add_child(sp)
	_cutscene()


func _cutscene() -> void:
	var e: Array = DIR.gej(3, [])
	e.append(4)
	DIR.sej(3, e)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	var tw2 := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw2.tween_interval(12.0)
	tw2.tween_callback(func() -> void:
		SOL.add_ui_child(end_credits)
		await get_tree().process_frame
		end_credits.play()
	)
	camera.zoom = Vector2(8.0, 8.0)
	tw.tween_property(white, ^"color", Color.TRANSPARENT, 6.0).from(Color.WHITE)
	tw.set_ease(Tween.EASE_OUT).tween_property(camera, "zoom", Vector2(0.5, 0.5), 30.0)
