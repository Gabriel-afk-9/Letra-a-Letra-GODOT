extends RefCounted
class_name GameInternalEvent


var event_name: String

var _data: Dictionary


func _init(
	p_event_name: String,
	p_data: Dictionary = {}
) -> void:
	event_name = p_event_name
	_data = p_data


static func from_dictionary(event_name: String, data: Dictionary) -> GameInternalEvent:
	return GameInternalEvent.new(event_name, data)


func get_cell_x() -> int:
	return _get_cell_coordinate("x")


func get_cell_y() -> int:
	return _get_cell_coordinate("y")


func get_founded_cells() -> Array[Vector2i]:
	var parsed_cells: Array[Vector2i] = []

	var raw_cells = _data.get("cells")

	if not raw_cells is Array:
		return parsed_cells

	for raw_cell in raw_cells:
		if not raw_cell is Dictionary:
			continue

		var cell: Dictionary = raw_cell

		var raw_x = cell.get("x")
		var raw_y = cell.get("y")

		if not raw_x is int and not raw_x is float:
			continue

		if not raw_y is int and not raw_y is float:
			continue

		parsed_cells.append(Vector2i(int(raw_x), int(raw_y)))

	return parsed_cells


func get_founded_by_player_id() -> String:
	return _get_string_field("foundedBy")


func get_revealed_by_player_id() -> String:
	return _get_string_field("revealedBy")


func contains_player_id(player_id: String) -> bool:
	for value in _data.values():
		if str(value) == player_id:
			return true

	return false


func _get_cell_coordinate(axis: String) -> int:
	if not _data.has("cell"):
		return -1

	var cell = _data.get("cell")

	if not cell is Dictionary:
		return -1

	var raw_value = cell.get(axis)

	if raw_value is int or raw_value is float:
		return int(raw_value)

	return -1


func _get_string_field(key: String) -> String:
	var raw_value = _data.get(key)

	if raw_value == null:
		return ""

	return str(raw_value)