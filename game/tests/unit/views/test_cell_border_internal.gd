extends GutTest

func test_revealed_uses_internal_border_not_shadow() -> void:
	var gd := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	var cell := FileAccess.get_file_as_string("res://assets/components/game/board/cell_view.gd")
	var combined := gd + cell
	assert_true(combined.contains("REVEALED_ME") and combined.contains("COLOR_WHITE") and combined.contains("COLOR_TEXT_DARK"), "REVEALED_ME deve ter borda externa preta")
	assert_true(combined.contains("_update_inner_border") or combined.contains("_update_cell_inner_border"), "REVEALED_ME inner border helper existe")
	assert_true(combined.contains("COLOR_BLUE") and combined.contains("COLOR_ORANGE"), "cores azul/laranja existem")

func test_no_outer_shiny_shadow_for_revealed() -> void:
	var cell := FileAccess.get_file_as_string("res://assets/components/game/board/cell_view.gd")
	assert_false(cell.contains("COLOR_BLUE, COLOR_BLUE") and cell.contains("REVEALED_ME"), "REVEALED não deve usar shadow azul externo")
	assert_true(cell.contains("InnerBorder") or cell.contains("_inner_border"), "inner border layer existe")

func test_border_width_is_2() -> void:
	var cell := FileAccess.get_file_as_string("res://assets/components/game/board/cell_view.gd")
	assert_true(cell.contains("CELL_BORDER_WIDTH := 3"), "borda 3px no CellView")
	assert_true(cell.contains("CELL_INNER_CORNER_RADIUS"), "inner radius const existe")
	assert_true(cell.contains("InnerBorder"), "InnerBorder layer existe")

func test_hidden_uses_black_border_and_trap_block_colored_bg() -> void:
	var cell := FileAccess.get_file_as_string("res://assets/components/game/board/cell_view.gd")
	assert_true(cell.contains("TRAP_ME") and cell.contains("COLOR_BLUE"), "TRAP_ME existe no CellView")
	assert_true(cell.contains("BLOCK_ME"), "BLOCK_ME existe no CellView")
	assert_true(cell.contains("SPY_ME") and cell.contains("SPY_BORDER"), "SPY existe")
	assert_true(cell.contains("BLINDED") and cell.contains("COLOR_BLIND_BG"), "BLIND existe")
	assert_true(cell.contains("_update_inner_border") or cell.contains("InnerBorder"), "inner border helper existe")
