extends GutTest

func test_claimed_both_uses_diagonal_bottom_left_blue_top_right_orange() -> void:
	var gd := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	assert_true(gd.contains("CELL_STATE_CLAIMED_BOTH"), "deve ter CLAIMED_BOTH")
	assert_true(gd.contains("_update_cell_diagonal_split"), "deve chamar diagonal")
	assert_true(gd.contains("DiagonalSplit"), "layer DiagonalSplit")
	assert_true(gd.contains("COLOR_BLUE") and gd.contains("COLOR_ORANGE"), "diagonal usa azul e laranja")
	assert_true(gd.contains("uv.y > uv.x") or gd.contains("color_a") and gd.contains("color_b"), "diagonal bottom-left azul (y>x) top-right laranja")

func test_diagonal_uses_shader_rounded_5() -> void:
	var gd := FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	assert_true(gd.contains("_diagonal_split_material"), "shader helper")
	assert_true(gd.contains("radius = 5.0") or gd.contains("radius"), "rounded 5")
	assert_true(gd.contains("show_behind_parent = true"), "behind parent para letra branca")
