extends PanelContainer
class_name BoardView


signal cell_pressed(pos: Vector2i)

const BOARD_SIZE := 10
const CELL_VIEW_SCENE := preload("res://assets/components/game/board/cell_view.tscn")
const COLOR_NEON_GREEN := Color(0.2, 1.0, 0.4, 1)
const BOARD_PULSE_DURATION := 0.6
const BOARD_PULSE_MAX_SHADOW := 8

var _cell_views: Dictionary = {}
var _pulse_tween: Tween
@onready var _grid: GridContainer = $BoardGrid


func _ready() -> void:
	_grid.columns = BOARD_SIZE
	_grid.add_theme_constant_override("h_separation", 1)
	_grid.add_theme_constant_override("v_separation", 1)
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_build_cells()


func _build_cells() -> void:
	_cell_views.clear()
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var cell: CellView = CELL_VIEW_SCENE.instantiate()
			cell.setup(Vector2i(x, y))
			cell.cell_pressed.connect(_on_cell_pressed)
			_grid.add_child(cell)
			_cell_views[Vector2i(x, y)] = cell


func _on_cell_pressed(pos: Vector2i) -> void:
	cell_pressed.emit(pos)


func get_cell(pos: Vector2i) -> CellView:
	return _cell_views.get(pos) as CellView


func get_all_cells() -> Dictionary:
	return _cell_views


func apply_responsive(layout_w: float, cell_size: int, font_sz: int) -> void:
	custom_minimum_size = Vector2(float(BOARD_SIZE) * float(cell_size) + 16.0 + 8.0 + 9.0, 0)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_grid.add_theme_constant_override("h_separation", 1)
	_grid.add_theme_constant_override("v_separation", 1)
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for pos in _cell_views:
		var cv: CellView = _cell_views[pos]
		if cv != null:
			cv.custom_minimum_size = Vector2(cell_size, cell_size)
			cv.add_theme_font_size_override("font_size", font_sz)
			cv.pivot_offset = Vector2(cell_size, cell_size) / 2.0


func set_board_pulse(enabled: bool) -> void:
	var style := get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	if is_instance_valid(_pulse_tween) and _pulse_tween.is_valid():
		_pulse_tween.kill()
	if not enabled:
		style.shadow_size = 0
		return
	style.shadow_color = COLOR_NEON_GREEN
	style.shadow_size = 0
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(style, "shadow_size", BOARD_PULSE_MAX_SHADOW, BOARD_PULSE_DURATION)
	_pulse_tween.tween_property(style, "shadow_size", 0, BOARD_PULSE_DURATION)


func set_interactivity(disabled: bool, revealed_states: Dictionary = {}) -> void:
	_grid.modulate = Color.WHITE
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP
	for pos in _cell_views:
		var cv: CellView = _cell_views[pos]
		if cv == null:
			continue
		var is_revealed: bool = bool(revealed_states.get(pos, false))
		var cell_disabled: bool = disabled or is_revealed
		cv.set_cell_enabled(not cell_disabled)


func play_word_pulse_sequence(cells: Array[Vector2i]) -> void:
	_play_sequence(cells, 0)


func _play_sequence(cells: Array[Vector2i], idx: int) -> void:
	if idx >= cells.size():
		return
	var pos: Vector2i = cells[idx]
	var cv: CellView = _cell_views.get(pos) as CellView
	if cv != null:
		cv.pulse_word()
	if idx + 1 < cells.size():
		await (Engine.get_main_loop() as SceneTree).create_timer(0.18).timeout
		_play_sequence(cells, idx + 1)
