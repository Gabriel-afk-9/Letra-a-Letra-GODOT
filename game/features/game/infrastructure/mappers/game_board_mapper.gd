extends RefCounted

class_name GameBoardMapper


static func to_domain(board_data: Array) -> GameBoard:
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
					GameCellMapper.to_domain(raw_cell, row_index, column_index)
				)

		parsed_rows.append(parsed_row)

	return GameBoard.new(parsed_rows)
