extends GutTest

var _board: BoardView

func before_each() -> void:
	var scene: PackedScene = load("res://assets/components/game/board/board_view.tscn")
	_board = scene.instantiate()
	add_child(_board)
	await get_tree().process_frame

func after_each() -> void:
	_board.queue_free()

func test_board_math_constants_are_preserved() -> void:
	var gd = FileAccess.get_file_as_string("res://features/game/presentation/views/game_screen.gd")
	assert_true(gd.contains("layout_w * 0.90"), "avail deve ser layout_w * 0.90")
	assert_true(gd.contains("16.0 + 8.0 + 9.0"), "chrome deve ser 16+8+9=33")
	assert_true(gd.contains("floor((avail - chrome) / 10.0)"), "cell deve usar floor((avail-chrome)/10)")
	assert_true(gd.contains("clamp(cell_f, 30.0, 96.0)"), "clamp 30-96 deve existir")
	assert_true(gd.contains("clampi(int(cell * 0.42), 12, 18)"), "font 0.42 clamp 12-18 deve existir")
	assert_true(gd.contains("10.0 * float(cell) + chrome"), "wrapper 10*cell+chrome deve existir")

func test_apply_responsive_standard_size() -> void:
	_board.apply_responsive(456.0, 37, 15)
	assert_eq(_board.custom_minimum_size.x, 403.0, "wrapper 10*37+33=403 em 456")
	assert_eq(_board.size_flags_horizontal, Control.SIZE_SHRINK_CENTER, "board deve ser SHRINK_CENTER")
	var grid: GridContainer = _board.get_node("BoardGrid")
	assert_eq(grid.get_theme_constant("h_separation"), 1, "h_separation 1")
	assert_eq(grid.get_theme_constant("v_separation"), 1, "v_separation 1")
	assert_eq(grid.size_flags_horizontal, Control.SIZE_SHRINK_CENTER, "grid SHRINK_CENTER")
	for pos in _board.get_all_cells():
		var cv: CellView = _board.get_all_cells()[pos] as CellView
		assert_eq(cv.custom_minimum_size, Vector2(37, 37), "cell 37x37")
		assert_eq(cv.get_theme_font_size("font_size"), 15, "font 15")
		break

func test_apply_responsive_small_clamps_to_30() -> void:
	var avail_small = 180.0
	var cell_f_small = floor((avail_small - 33.0) / 10.0)
	var cell_small = clampi(int(cell_f_small), 30, 96)
	assert_eq(cell_small, 30, "small clamp deve ser 30")
	_board.apply_responsive(200.0, cell_small, 12)
	assert_eq(_board.custom_minimum_size.x, 333.0, "wrapper 10*30+33=333")
	var cv: CellView = _board.get_all_cells()[Vector2i(0, 0)] as CellView
	assert_eq(cv.custom_minimum_size, Vector2(30, 30), "cell clamp 30")
	assert_eq(cv.get_theme_font_size("font_size"), 12, "font clamp 12")

func test_apply_responsive_large_clamps_to_96() -> void:
	var avail_large = 1080.0
	var cell_f_large = floor((avail_large - 33.0) / 10.0)
	var cell_large = clampi(int(cell_f_large), 30, 96)
	assert_eq(cell_large, 96, "large clamp deve ser 96")
	_board.apply_responsive(1200.0, cell_large, 18)
	assert_eq(_board.custom_minimum_size.x, 993.0, "wrapper 10*96+33=993")
	var cv: CellView = _board.get_all_cells()[Vector2i(5, 5)] as CellView
	assert_eq(cv.get_theme_font_size("font_size"), 18, "font clamp 18")

func test_apply_responsive_updates_all_cells_and_pivot() -> void:
	_board.apply_responsive(456.0, 42, 17)
	for pos in _board.get_all_cells():
		var cv: CellView = _board.get_all_cells()[pos] as CellView
		assert_eq(cv.custom_minimum_size, Vector2(42, 42), "cada cell deve atualizar")
		assert_eq(cv.pivot_offset, Vector2(21, 21), "pivot deve ser cell/2")
		break

func test_board_has_100_cells_and_grid_is_10() -> void:
	assert_eq(_board.get_all_cells().size(), 100, "board 10x10=100 cells")
	assert_eq(_board.get_node("BoardGrid").columns, 10, "grid columns 10")
	for x in range(10):
		for y in range(10):
			assert_not_null(_board.get_cell(Vector2i(x, y)), "cell deve existir")
			break
		break
