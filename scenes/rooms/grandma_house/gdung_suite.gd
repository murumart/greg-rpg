class_name GDUNGSuite

enum {_XPOS, _YPOS, _XSIZE, _YSIZE, _DSIZE}
var id: int
var _data: PackedByteArray
var neighbors := {
	SIDE_BOTTOM: [],
	SIDE_RIGHT: []
}
var door_positions: Array[Vector2i] = []
var generated_objects: Array[Dictionary] = []


static func create_from_rect(rect: Rect2i) -> GDUNGSuite:
	var suite := GDUNGSuite.new()
	suite._data.resize(_DSIZE)
	suite._data[_XPOS] = rect.position.x
	suite._data[_YPOS] = rect.position.y
	suite._data[_XSIZE] = rect.size.x
	suite._data[_YSIZE] = rect.size.y
	return suite


static func create_from_array(array: PackedByteArray) -> GDUNGSuite:
	assert(array.size() >= _DSIZE, "array isn't large enough (" + str(array.size()) + ")")
	var suite := GDUNGSuite.new()
	suite._data.resize(_DSIZE)
	for i in _DSIZE:
		suite._data[i] = array[i]
	return suite


static func remove_4_from_array(array: PackedByteArray) -> PackedByteArray:
	return array.slice(_DSIZE)


static func split_array_horizontally(input: PackedByteArray, where: int) -> PackedByteArray:
	var array := PackedByteArray()
	array.resize(_DSIZE * 2)
	array[_XPOS] = input[_XPOS]
	array[_YPOS] = input[_YPOS]
	array[_XSIZE] = where
	array[_YSIZE] = input[_YSIZE]

	array[_XPOS + _DSIZE] = input[_XPOS] + where
	array[_YPOS + _DSIZE] = input[_YPOS]
	array[_XSIZE + _DSIZE] = input[_XSIZE] - where
	array[_YSIZE + _DSIZE] = input[_YSIZE]
	return array


static func split_array_vertically(input: PackedByteArray, where: int) -> PackedByteArray:
	var array := PackedByteArray()
	array.resize(_DSIZE * 2)
	array[_XPOS] = input[_XPOS]
	array[_YPOS] = input[_YPOS]
	array[_XSIZE] = input[_XSIZE]
	array[_YSIZE] = where

	array[_XPOS + _DSIZE] = input[_XPOS]
	array[_YPOS + _DSIZE] = input[_YPOS] + where
	array[_XSIZE + _DSIZE] = input[_XSIZE]
	array[_YSIZE + _DSIZE] = input[_YSIZE] - where
	return array


func get_rect() -> Rect2i:
	return Rect2i(_data[_XPOS], _data[_YPOS], _data[_XSIZE], _data[_YSIZE])


func get_x_size() -> int:
	return _data[_XSIZE]


func get_y_size() -> int:
	return _data[_YSIZE]


func get_position() -> Vector2i:
	return Vector2i(_data[_XPOS], _data[_YPOS])


func add_neighbor(n: GDUNGSuite, direction: int) -> void:
	neighbors[direction].append(n)


func has_neighbors() -> bool:
	for x in neighbors:
		if not neighbors[x].is_empty():
			return true
	return false


func add_generated_object(key: StringName, object: Dictionary, instance: Node2D, ob_id: int) -> void:
	var rect := Rect2i(Vector2i(
			(instance.global_position) / 16.0) - get_position(),
			object.get(GDUNGObjects.SIZE))
	generated_objects.append(
				{"key": key, "object": object, "rect": rect, "instance": instance, "id": ob_id})
