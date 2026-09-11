extends GutTest

func test_revealed_uses_internal_border_not_shadow() -> void:
	var text := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	assert_true(text.contains("CELL_STATE_REVEALED_ME:\n\t\t\t_style_cell(button, COLOR_WHITE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, Color.BLACK)"), "REVEALED_ME deve ter borda externa preta")
	assert_true(text.contains("_update_cell_inner_border(button, COLOR_BLUE)"), "REVEALED_ME inner azul")
	assert_true(text.contains("CELL_STATE_REVEALED_OPPONENT:\n\t\t\t_style_cell(button, COLOR_WHITE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, Color.BLACK)"), "REVEALED_OPP externa preta")
	assert_true(text.contains("_update_cell_inner_border(button, COLOR_ORANGE)"), "REVEALED_OPP inner laranja")
	assert_true(text.contains("CELL_STATE_CLAIMED_ME:\n\t\t\t_style_cell(button, COLOR_BLUE, Color(0, 0, 0, 0), COLOR_WHITE, Color.BLACK)"), "CLAIMED_ME borda preta")
	assert_true(text.contains("CELL_STATE_CLAIMED_OPPONENT:\n\t\t\t_style_cell(button, COLOR_ORANGE, Color(0, 0, 0, 0), COLOR_WHITE, Color.BLACK)"), "CLAIMED_OPP borda preta")

func test_no_outer_shiny_shadow_for_revealed() -> void:
	var text := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	assert_false(text.contains("_style_cell(button, COLOR_WHITE, COLOR_BLUE, COLOR_TEXT_DARK)"), "antigo outer shadow azul não deve existir")
	assert_false(text.contains("_style_cell(button, COLOR_WHITE, COLOR_ORANGE, COLOR_TEXT_DARK)"), "antigo outer shadow laranja não deve existir")
	assert_false(text.contains("_style_cell(button, COLOR_BLUE, COLOR_BLUE, COLOR_WHITE)"), "antigo CLAIMED com shadow não deve existir sem inner")

func test_border_width_is_2() -> void:
	var text := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	assert_true(text.contains("const CELL_BORDER_WIDTH := 3"), "borda interna deve ser 3px conforme pedido 1 nivel a mais")
	assert_true(text.contains("const CELL_INNER_CORNER_RADIUS := 4"), "inner mais redonda 7 para contraste com outer 5")
	assert_true(text.contains("set_corner_radius_all(CELL_INNER_CORNER_RADIUS)"), "inner usa const 7")

func test_hidden_uses_black_border_and_trap_block_colored_bg() -> void:
	var text := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	assert_true(text.contains("CELL_STATE_TRAP_ME:\n\t\t\t_style_cell(button, COLOR_BLUE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, Color.BLACK)"), "TRAP_ME bg azul border preta")
	assert_true(text.contains("CELL_STATE_BLOCK_ME:\n\t\t\t_style_cell(button, COLOR_BLUE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, Color.BLACK)"), "BLOCK_ME bg azul border preta")
	assert_true(text.contains("CELL_STATE_SPY_ME:\n\t\t\t_style_cell(button, COLOR_WHITE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, COLOR_SPY_BORDER)"), "SPY cinza")
	assert_true(text.contains("CELL_STATE_BLINDED:\n\t\t\t_style_cell(button, COLOR_BLIND_BG, Color(0, 0, 0, 0), COLOR_BLIND_BG, Color.BLACK)"), "BLIND toda preta")
	assert_true(text.contains("_:\n\t\t\t_style_cell(button, COLOR_WHITE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, Color.BLACK)"), "HIDDEN default preta")
	assert_true(text.contains("_update_cell_inner_border"), "helper inner existe")
