extends GutTest


func test_board_empty_array_returns_empty_board() -> void:
	var board := GameBoardMapper.to_domain([])

	assert_not_null(board)
	assert_eq(board.rows.size(), 0)


func test_board_1x1_revealed_letter() -> void:
	var board := GameBoardMapper.to_domain([
		[{"letter": "A", "revealed": true, "revealedBy": "id1"}]
	])

	assert_eq(board.rows.size(), 1)
	assert_eq(board.rows[0].size(), 1)
	var cell: GameCell = board.get_cell(0, 0)
	assert_not_null(cell)
	assert_eq(cell.letter, "A")
	assert_true(cell.revealed)
	assert_eq(cell.revealed_by_player_id, "id1")
	assert_eq(cell.x, 0)
	assert_eq(cell.y, 0)


func test_board_2x2_with_effect_block() -> void:
	var board := GameBoardMapper.to_domain([
		[{"letter": "A", "revealed": true}, {"letter": "B", "revealed": false, "effect": {"effect": "BLOCK"}}],
		[{"letter": "C", "revealed": false}, {"letter": "D", "revealed": true}]
	])

	assert_eq(board.rows.size(), 2)
	assert_eq(board.rows[0].size(), 2)
	var cell_block: GameCell = board.get_cell(0, 1)
	assert_not_null(cell_block)
	assert_eq(cell_block.effect_type, "BLOCK")
	var cell_plain: GameCell = board.get_cell(1, 0)
	assert_eq(cell_plain.effect_type, "")


func test_board_ignores_non_array_rows() -> void:
	var board := GameBoardMapper.to_domain([
		"not_an_array",
		[{"letter": "Z", "revealed": true}]
	])

	# Deve ignorar linha inválida e parsear só a segunda
	assert_eq(board.rows.size(), 1)
