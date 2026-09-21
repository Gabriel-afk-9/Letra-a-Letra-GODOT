extends RefCounted
class_name BoardFactory

static func revealed_cell(letter: String, revealed_by: String = "me") -> Dictionary:
	return {"revealed": true, "letter": letter, "revealedBy": revealed_by}

static func hidden_cell() -> Dictionary:
	return {"revealed": false, "letter": null}

static func board_1x1(letter: String, revealed_by: String = "me") -> GameBoard:
	return GameBoardMapper.to_domain([[revealed_cell(letter, revealed_by)]])

static func board_2x2(block_at: Vector2i = Vector2i(-1, -1)) -> GameBoard:
	var rows: Array = []
	for y in 2:
		var row: Array = []
		for x in 2:
			if Vector2i(x, y) == block_at:
				row.append({"revealed": false, "letter": null, "effect": {"effect": "BLOCK"}, "effectOwnerId": "me", "remainingClicks": 3})
			else:
				row.append({"revealed": false, "letter": null})
		rows.append(row)
	return GameBoardMapper.to_domain(rows)
