class_name SlidingPuzzle extends Node2D

signal finished(win: bool)

enum States {SOMETHING_ELSE, PLAYING}

const PADDING := 2
const DIRECTIONS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const STONE_MAT := preload(
		"res://scenes/rooms/forest/sliding_puzzle/rock_pizzle_piece_material.tres")

@onready var tile_haver: Panel = $TileHaver
@onready var pointer: Panel = $Pointer
var pointer_position := Vector2i.ZERO

@onready var rock_sound: AudioStreamPlayer = $RockSound
@onready var select_sound: AudioStreamPlayer = $SelectSound

@export var puzzle_size := 4
@export var image_texture: Texture2D

var tiles: Array[TextureRect] = []
var state := States.SOMETHING_ELSE
var time := 0.0


func _ready() -> void:
	pointer.size = Math.v2(get_piece_size())
	if is_instance_valid(SND.current_song_player):
		var tw := create_tween()
		tw.tween_property(SND.current_song_player, "pitch_scale", 0.88, 0.6)
	clear()
	_generate_puzzleboard()
	_shuffle()
	_select_tiles()
	state = States.PLAYING


func _process(delta: float) -> void:
	time += delta


func _unhandled_key_input(_event: InputEvent) -> void:
	if not state == States.PLAYING:
		return
	if Input.is_action_just_pressed("cancel") and time > 1.0:
		_lose()
		return
	_select_tiles()
	_move_tiles()


func _select_tiles() -> void:
	var move := Vector2i(Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down"))
	var size := tile_haver.size.x - PADDING * 2
	var piecesize := int(size / float(puzzle_size))

	var last_position := pointer_position
	pointer_position = Vector2(
			clampi(pointer_position.x + move.x, 0, puzzle_size - 1),
			clampi(pointer_position.y + move.y, 0, puzzle_size - 1))

	pointer.global_position = tile_haver.global_position + Vector2(
			PADDING + piecesize * pointer_position.x,
			PADDING + piecesize * pointer_position.y)
	if last_position != pointer_position:
		select_sound.play()


func _move_tiles() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		var direction := _get_tile_move_direction(pointer_position)
		if direction == Vector2i.ZERO:
			return
		_move_tile(pointer_position, direction)
		rock_sound.play()
		if is_sorted():
			_win()


func _win() -> void:
	state = States.SOMETHING_ELSE
	await get_tree().process_frame
	SND.play_sound(preload("res://sounds/pennistong/pennistong_win.ogg"))
	SOL.dialogue("sliding_puzzle_win")
	await SOL.dialogue_closed
	finished.emit(true)


func _lose() -> void:
	state = States.SOMETHING_ELSE
	await get_tree().process_frame
	SND.play_sound(preload("res://sounds/pennistong/pennistong_lose.ogg"))
	SOL.dialogue("sliding_puzzle_lose")
	await SOL.dialogue_closed
	finished.emit(false)


func _generate_puzzleboard() -> void:
	var piecesize := get_piece_size()
	var tile_nr := 0
	for y in puzzle_size:
		for x in puzzle_size:
			if tile_nr >= puzzle_size * puzzle_size - 1:
				break
			var rect := TextureRect.new()
			tile_haver.add_child(rect)
			rect.position = Vector2(
					PADDING + piecesize * x,
					PADDING + piecesize * y)
			rect.size = Vector2(piecesize, piecesize)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.material = STONE_MAT
			rect.set_meta("number", tile_nr)

			var tsize := image_texture.get_width()
			var ttilesize := int(tsize / float(puzzle_size))
			var texture := AtlasTexture.new()
			texture.atlas = image_texture
			texture.region.position = Vector2(ttilesize * x, ttilesize * y)
			texture.region.size = Vector2(ttilesize, ttilesize)
			rect.texture = texture

			var label := Label.new()
			rect.add_child(label)
			label.text = str(tile_nr + 1)
			tile_nr += 1
			tiles.append(rect)
			label.add_theme_constant_override("outline_size", 2)
			label.add_theme_color_override("font_outline_color", Color.BLACK)
	tiles.append(null) # empty spot


func _get_tile_position(pos: Vector2i) -> Vector2:
	var piecesize := get_piece_size()
	return Vector2(
		PADDING + piecesize * pos.x,
		PADDING + piecesize * pos.y)


func get_tile_haver_size() -> int:
	return int(tile_haver.size.x - PADDING * 2)


func get_piece_size() -> int:
	return int(get_tile_haver_size() / float(puzzle_size))


func get_tile_index(pos: Vector2i) -> int:
	return pos.y * puzzle_size + pos.x


func get_tile_pos(index: int) -> Vector2i:
	var x := index % puzzle_size
	var y := int(index / puzzle_size)
	return Vector2i(x, y)


func get_tile_by_pos(pos: Vector2i) -> Variant:
	if pos.x >= puzzle_size or pos.x < 0:
		return false
	if pos.y >= puzzle_size or pos.y < 0:
		return false
	return tiles[get_tile_index(pos)]


func get_tile_by_index(index: int) -> TextureRect:
	if index >= tiles.size() or index < 0:
		return null
	return tiles[index]


func _get_tile_move_direction(pos: Vector2i) -> Vector2i:
	var index := get_tile_index(pos)
	var tile := tiles[index]
	if not tile:
		return Vector2i.ZERO
	var top_tile: Variant = get_tile_by_pos(pos + Vector2i.UP)
	var bottom_tile: Variant = get_tile_by_pos(pos + Vector2i.DOWN)
	var right_tile: Variant = get_tile_by_pos(pos + Vector2i.RIGHT)
	var left_tile: Variant = get_tile_by_pos(pos + Vector2i.LEFT)
	if top_tile == null:
		return Vector2i.UP
	elif bottom_tile == null:
		return Vector2i.DOWN
	elif left_tile == null:
		return Vector2i.LEFT
	elif right_tile == null:
		return Vector2i.RIGHT
	return Vector2i.ZERO


func _move_tile(pos: Vector2i, direction: Vector2i) -> void:
	var index := get_tile_index(pos)
	var movindex := get_tile_index(pos + direction)
	var tile := get_tile_by_index(index)
	tiles[index] = null
	tiles[movindex] = tile
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(tile, "position", _get_tile_position(pos + direction), 0.1)


func _shuffle() -> void:
	var times := 200
	var selection_position := Vector2i(puzzle_size - 1, puzzle_size - 1)
	var last_direction := Vector2i.ZERO
	for _x in times:
		var last_position := selection_position
		var direction := _get_random_direction_around_empty(last_position, -last_direction)
		selection_position += direction
		_move_tile(selection_position, -direction)
		last_direction = direction
		#await Math.timer(0.1)


func _get_random_direction_around_empty(pos: Vector2i, last_dir: Vector2i) -> Vector2i:
	var positions: Array[Vector2i] = []
	for dir in DIRECTIONS:
		var what_we_get = get_tile_by_pos(pos + dir)
		if not what_we_get or dir == last_dir:
			continue
		positions.append(dir)
	return positions.pick_random()


func clear() -> void:
	tile_haver.get_children().map(func(a: Node): a.queue_free())
	tiles.clear()
	pointer_position = Vector2i.ZERO


func is_sorted() -> bool:
	var last := -1
	if not tiles.back() == null:
		return false
	for tile in tiles:
		#print(tile)
		if tile == null:
			continue
		var nr: int = tile.get_meta("number", -1)
		#prints(nr, last)
		if not nr - last == 1:
			return false
		last = nr
	return true
