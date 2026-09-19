extends GutTest

var _cv: CellView

func before_each() -> void:
	var scene: PackedScene = load("res://assets/components/game/board/cell_view.tscn")
	_cv = scene.instantiate()
	add_child(_cv)
	await get_tree().process_frame

func after_each() -> void:
	_cv.queue_free()

func test_hidden_and_revealed_styles() -> void:
	_cv.apply_state("HIDDEN", "", [], 30.0)
	var style_hidden: StyleBoxFlat = _cv.get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(style_hidden.bg_color, Color(1, 1, 1, 1), "HIDDEN bg WHITE")
	_cv.apply_state("REVEALED_ME", "A", [], 30.0)
	var style_rm: StyleBoxFlat = _cv.get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(style_rm.bg_color, Color(1, 1, 1, 1), "REVEALED_ME bg WHITE")
	assert_eq(_cv.get_theme_color("font_color"), Color(0.15, 0.15, 0.15, 1), "REVEALED_ME font dark")
	assert_true(_cv.get_node("InnerBorder").visible, "REVEALED_ME deve ter InnerBorder")
	_cv.apply_state("REVEALED_OPPONENT", "B", [], 30.0)
	var style_ro: StyleBoxFlat = _cv.get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(style_ro.bg_color, Color(1, 1, 1, 1), "REVEALED_OPPONENT bg WHITE")

func test_claimed_styles() -> void:
	_cv.apply_state("CLAIMED_ME", "C", [], 30.0)
	var s_me: StyleBoxFlat = _cv.get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(s_me.bg_color, Color(0.101960786, 0.57254905, 0.9019608, 1), "CLAIMED_ME bg BLUE")
	assert_eq(_cv.get_theme_color("font_color"), Color(1, 1, 1, 1), "CLAIMED_ME font WHITE")
	_cv.apply_state("CLAIMED_OPPONENT", "D", [], 30.0)
	var s_opp: StyleBoxFlat = _cv.get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(s_opp.bg_color, Color(0.9529412, 0.52156866, 0.09411765, 1), "CLAIMED_OPPONENT bg ORANGE")
	_cv.apply_state("CLAIMED_BOTH", "E", [], 30.0)
	var s_both: StyleBoxFlat = _cv.get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(s_both.bg_color, Color(0, 0, 0, 0), "CLAIMED_BOTH bg transparent")
	assert_true(_cv.get_node("DiagonalSplit").visible, "CLAIMED_BOTH deve ter DiagonalSplit")
	assert_true(_cv.get_node("DiagonalSplit").clip_contents, "Diagonal deve clip")
	assert_true(_cv.get_node("DiagonalSplit").show_behind_parent, "Diagonal deve show_behind_parent")

func test_blind_spy_trap_block_styles() -> void:
	_cv.apply_state("BLINDED", "", [], 30.0)
	var s_blind: StyleBoxFlat = _cv.get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(s_blind.bg_color, Color(0.05, 0.05, 0.05, 1), "BLINDED bg 0.05")
	_cv.apply_state("SPY_ME", "F", [], 30.0)
	var s_spy: StyleBoxFlat = _cv.get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(s_spy.border_color, Color(0.6, 0.6, 0.6, 1), "SPY border cinza")
	_cv.apply_state("TRAP_ME", "G", [], 30.0)
	assert_true(_cv.get_node("TrapIcon").visible, "TRAP_ME deve mostrar TrapIcon")
	_cv.apply_state("TRAP_OPPONENT", "H", [], 30.0)
	assert_true(_cv.get_node("TrapIcon").visible, "TRAP_OPPONENT deve mostrar TrapIcon")
	_cv.apply_state("BLOCK_ME", "I", [Color(0.101960786, 0.57254905, 0.9019608, 1), Color.WHITE, Color.WHITE], 30.0)
	assert_true(_cv.get_node("BlockBar").visible, "BLOCK_ME deve mostrar BlockBar")
	_cv.apply_state("BLOCK_OPPONENT", "J", [Color(0.9529412, 0.52156866, 0.09411765, 1), Color.WHITE, Color.WHITE], 50.0)
	var bar: Control = _cv.get_node("BlockBar")
	var center: CenterContainer = bar.get_child(0) as CenterContainer
	var hbox: HBoxContainer = center.get_child(0) as HBoxContainer
	assert_eq(hbox.get_child_count(), 3, "BLOCK deve ter 3 segmentos")
	var seg: Panel = hbox.get_child(0) as Panel
	assert_true(seg.custom_minimum_size.x >= 7.0 and seg.custom_minimum_size.x <= 8.0, "BLOCK dot deve ser clamp 7-8")
	_cv.apply_state("BLOCK_ME", "K", [Color.BLUE], 30.0)
	var bar2: Control = _cv.get_node("BlockBar")
	var center2: CenterContainer = bar2.get_child(0) as CenterContainer
	var hbox2: HBoxContainer = center2.get_child(0) as HBoxContainer
	var seg2: Panel = hbox2.get_child(0) as Panel
	assert_eq(seg2.custom_minimum_size, Vector2(7, 7), "BLOCK 30 deve ter dot 7")

func test_border_width_and_layers_are_ignored_for_click() -> void:
	var cell_gd = FileAccess.get_file_as_string("res://assets/components/game/board/cell_view.gd")
	assert_true(cell_gd.contains("CELL_BORDER_WIDTH := 3"), "border width 3")
	assert_true(cell_gd.contains("CELL_CORNER_RADIUS := 5"), "corner 5")
	_cv.apply_state("HIDDEN", "", [], 30.0)
	assert_eq(_cv.mouse_filter, Control.MOUSE_FILTER_STOP, "enabled deve ser STOP")
	_cv.set_cell_enabled(false)
	assert_eq(_cv.mouse_filter, Control.MOUSE_FILTER_IGNORE, "disabled deve ser IGNORE")
	_cv.set_cell_enabled(true)
	assert_eq(_cv.mouse_filter, Control.MOUSE_FILTER_STOP, "re-enabled deve ser STOP")
	for layer_name in ["InnerBorder", "DiagonalSplit", "TrapIcon", "BlockBar"]:
		var layer: Control = _cv.get_node(layer_name) as Control
		assert_eq(layer.mouse_filter, Control.MOUSE_FILTER_IGNORE, "layer deve ser IGNORE")

func test_diagonal_shader_has_radius() -> void:
	var tscn = FileAccess.get_file_as_string("res://assets/components/game/board/cell_diagonal.gdshader")
	assert_true(tscn.contains("radius"), "shader deve ter radius")
	assert_true(tscn.contains("color_a") and tscn.contains("color_b"), "shader deve ter color_a/b")
	var gd = FileAccess.get_file_as_string("res://assets/components/game/board/cell_view.gd")
	assert_true(gd.contains("radius") and gd.contains("5.0"), "cell deve setar radius 5.0")

