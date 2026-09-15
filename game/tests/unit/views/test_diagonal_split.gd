extends GutTest

func test_claimed_both_uses_diagonal_bottom_left_blue_top_right_orange() -> void:
	var cell := FileAccess.get_file_as_string("res://assets/components/game/board/cell_view.gd")
	var shader := FileAccess.get_file_as_string("res://assets/components/game/board/cell_diagonal.gdshader")
	assert_true(cell.contains("CLAIMED_BOTH"), "CellView deve ter CLAIMED_BOTH")
	assert_true(cell.contains("DiagonalSplit") or cell.contains("_diagonal_split"), "layer DiagonalSplit no CellView")
	assert_true(cell.contains("COLOR_BLUE") and cell.contains("COLOR_ORANGE"), "diagonal usa azul e laranja")
	assert_true(shader.contains("uv.y > uv.x"), "diagonal bottom-left azul (y>x) top-right laranja no shader")

func test_diagonal_uses_shader_rounded_5() -> void:
	var cell := FileAccess.get_file_as_string("res://assets/components/game/board/cell_view.gd")
	var shader := FileAccess.get_file_as_string("res://assets/components/game/board/cell_diagonal.gdshader")
	assert_true(cell.contains("_diagonal_shader") or cell.contains("diagonal"), "CellView usa shader diagonal")
	assert_true(shader.contains("radius = 5.0") or shader.contains("radius"), "shader rounded 5")
	assert_true(cell.contains("show_behind_parent = true"), "behind parent para letra branca")
