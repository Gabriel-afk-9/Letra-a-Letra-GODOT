extends RefCounted
class_name GameBoard


var rows: Array[Array]


func _init(
	p_rows: Array[Array] = []
) -> void:
	rows = p_rows


func to_dictionary() -> Dictionary:
	var parsed_rows: Array = []

	for row in rows:
		var parsed_row: Array = []

		for cell in row:
			if cell is GameCell:
				parsed_row.append(cell.to_dictionary())

		parsed_rows.append(parsed_row)

	return {
		"rows": parsed_rows
	}


static func from_array(board_data: Array) -> GameBoard:
	var parsed_rows: Array[Array] = []

	for row_index in board_data.size():
		var raw_row = board_data[row_index]

		if not raw_row is Array:
			continue

		var parsed_row: Array = []

		for column_index in raw_row.size():
			var raw_cell = raw_row[column_index]

			if raw_cell is Dictionary:
				parsed_row.append(
					GameCell.from_dictionary(raw_cell, row_index, column_index)
				)

		parsed_rows.append(parsed_row)

	return GameBoard.new(parsed_rows)


func get_cell(x: int, y: int) -> GameCell:
	if x < 0 or x >= rows.size():
		return null

	var row = rows[x]

	if not row is Array:
		return null

	if y < 0 or y >= row.size():
		return null

	var cell = row[y]

	if cell is GameCell:
		return cell

	return null
