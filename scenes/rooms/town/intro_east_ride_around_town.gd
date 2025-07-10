extends Node2D

@export var greg: PlayerOverworld
@export var greg_camera: Camera2D
@onready var zerm_car: CarOverworld = $ZermCar

@export var final_destination: Marker2D
@export var dialogue_line: String
@export_file("scn_room_*.tscn") var next_room: String
@export var next_music: String

var going := false


func _ready() -> void:
	if LTS.gate_id != &"intro":
		queue_free()
		return
	greg.remove_child(greg_camera)
	greg.hide()
	greg.collision_layer = 0
	DAT.capture_player("cutscene")
	greg.global_position = global_position - Vector2(0, 800)
	zerm_car.add_child(greg_camera)
	greg_camera.position = Vector2()
	zerm_car.path_point_reached.connect(_car_ride_over)
	if dialogue_line:
		await Math.timer(0.5)
		SOL.dialogue(dialogue_line)


func _car_ride_over(point: Marker2D) -> void:
	if going: return
	if point != final_destination:
		return
	going = true
	zerm_car.moves = false
	LTS.gate_id = &"intro"
	SND.room_music_blockers += 1
	if next_music:
		SND.play_song(next_music, 0.05)
	LTS.level_transition(next_room)
