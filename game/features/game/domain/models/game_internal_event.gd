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
	# Tolerante a variantes do servidor: cells/wordCells/positions como Array
	# ou posição única {x,y}/{position:{x,y}} — sem varrer tabuleiro.
	var parsed_cells: Array[Vector2i] = []
	var raw_cells: Variant = null

	for key in ["cells", "wordCells", "positions", "coordinates", "word_cells"]:
		if _data.has(key):
			raw_cells = _data.get(key)
			break

	if raw_cells is Dictionary:
		var d: Dictionary = raw_cells
		if d.has("position") and d.get("position") is Dictionary:
			var p: Dictionary = d.get("position")
			var rx = p.get("x")
			var ry = p.get("y")
			if (rx is int or rx is float) and (ry is int or ry is float):
				parsed_cells.append(Vector2i(int(rx), int(ry)))
				return parsed_cells
		var rx2 = d.get("x")
		var ry2 = d.get("y")
		if (rx2 is int or rx2 is float) and (ry2 is int or ry2 is float):
			parsed_cells.append(Vector2i(int(rx2), int(ry2)))
			return parsed_cells

	if not raw_cells is Array:
		var fx := get_cell_x()
		var fy := get_cell_y()
		if fx >= 0 and fy >= 0:
			parsed_cells.append(Vector2i(fx, fy))
		return parsed_cells

	for raw_cell in raw_cells:
		if not raw_cell is Dictionary:
			continue

		var cell: Dictionary = raw_cell
		# Suporta {x,y} ou {position:{x,y}}
		var pos_dict: Variant = cell.get("position") if cell.has("position") else null
		var rx: Variant
		var ry: Variant
		if pos_dict is Dictionary:
			rx = (pos_dict as Dictionary).get("x")
			ry = (pos_dict as Dictionary).get("y")
		else:
			rx = cell.get("x")
			ry = cell.get("y")

		if not rx is int and not rx is float:
			continue

		if not ry is int and not ry is float:
			continue

		parsed_cells.append(Vector2i(int(rx), int(ry)))

	return parsed_cells


func get_founded_by_player_id() -> String:
	return _get_string_field("foundedBy")


func get_revealed_by_player_id() -> String:
	return _get_string_field("revealedBy")


func contains_player_id(player_id: String) -> bool:
	return _deep_contains(_data, player_id)


func _deep_contains(node: Variant, player_id: String) -> bool:
	if node is Dictionary:
		for value in (node as Dictionary).values():
			if _deep_contains(value, player_id):
				return true
		return false

	if node is Array:
		for value in (node as Array):
			if _deep_contains(value, player_id):
				return true
		return false

	if node == null:
		return false

	return str(node) == player_id


func _get_cell_coordinate(axis: String) -> int:
	for key in ["cell", "position"]:
		if not _data.has(key):
			continue

		var cell = _data.get(key)

		if not cell is Dictionary:
			continue

		var raw_value = (cell as Dictionary).get(axis)

		if raw_value is int or raw_value is float:
			return int(raw_value)

	return -1


func get_effect_position() -> Vector2i:
	return Vector2i(get_cell_x(), get_cell_y())


func _get_string_field(key: String) -> String:
	var raw_value = _data.get(key)

	if raw_value == null:
		return ""

	return str(raw_value)
