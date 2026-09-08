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
	return GameBoardMapper.to_domain(board_data)


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
