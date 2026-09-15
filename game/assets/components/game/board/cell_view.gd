extends Button
class_name CellView


signal cell_pressed(pos: Vector2i)

const CELL_BORDER_WIDTH := 3
const CELL_CORNER_RADIUS := 5
const CELL_INNER_CORNER_RADIUS := 4
const COLOR_WHITE := Color(1, 1, 1, 1)
const COLOR_TEXT_DARK := Color(0.15, 0.15, 0.15, 1)
const COLOR_SPY_BORDER := Color(0.6, 0.6, 0.6, 1)
const COLOR_BLUE := Color(0.101960786, 0.57254905, 0.9019608, 1)
const COLOR_ORANGE := Color(0.9529412, 0.52156866, 0.09411765, 1)
const COLOR_BLIND_BG := Color(0.05, 0.05, 0.05, 1)
const TRAP_CELL_ICON_PATH := "res://assets/images/powers/trap-cell.png"
const BLOCK_BAR_SEGMENTS := 3

var cell_pos: Vector2i = Vector2i(-1, -1)
var _shake_tween: Tween
var _icon_cache: Dictionary = {}
var _diagonal_shader: Shader = preload("res://assets/components/game/board/cell_diagonal.gdshader")

@onready var _inner_border: Control = $InnerBorder
@onready var _diagonal_split: Control = $DiagonalSplit
@onready var _trap_icon: Control = $TrapIcon
@onready var _block_bar: Control = $BlockBar


func _ready() -> void:
	pressed.connect(func() -> void: cell_pressed.emit(cell_pos))
	_clear_all_layers()


func setup(pos: Vector2i, initial_size: Vector2 = Vector2(30, 30)) -> void:
	cell_pos = pos
	custom_minimum_size = initial_size
	add_theme_font_size_override("font_size", 12)


func apply_state(state: String, letter: String, block_colors: Array = [], cell_size_for_block: float = -1.0) -> void:
	text = letter
	_clear_all_layers()
	match state:
		"REVEALED_ME":
			_style_cell(COLOR_WHITE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, Color.BLACK)
			_update_inner_border(COLOR_BLUE)
		"REVEALED_OPPONENT":
			_style_cell(COLOR_WHITE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, Color.BLACK)
			_update_inner_border(COLOR_ORANGE)
		"CLAIMED_ME":
			_style_cell(COLOR_BLUE, Color(0, 0, 0, 0), COLOR_WHITE, Color.BLACK)
			_update_inner_border(Color(0, 0, 0, 0))
		"CLAIMED_OPPONENT":
			_style_cell(COLOR_ORANGE, Color(0, 0, 0, 0), COLOR_WHITE, Color.BLACK)
			_update_inner_border(Color(0, 0, 0, 0))
		"CLAIMED_BOTH":
			_style_cell(Color(0, 0, 0, 0), Color(0, 0, 0, 0), COLOR_WHITE, Color.BLACK)
			_update_inner_border(Color(0, 0, 0, 0))
			_update_diagonal_split(COLOR_BLUE, COLOR_ORANGE)
		"SPY_ME":
			_style_cell(COLOR_WHITE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, COLOR_SPY_BORDER)
			_update_inner_border(Color(0, 0, 0, 0))
		"BLINDED":
			_style_cell(COLOR_BLIND_BG, Color(0, 0, 0, 0), COLOR_BLIND_BG, Color.BLACK)
			_update_inner_border(Color(0, 0, 0, 0))
		"TRAP_ME":
			_style_cell(COLOR_BLUE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, Color.BLACK)
			_update_inner_border(Color(0, 0, 0, 0))
			_update_trap_icon(true)
		"TRAP_OPPONENT":
			_style_cell(COLOR_ORANGE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, Color.BLACK)
			_update_inner_border(Color(0, 0, 0, 0))
			_update_trap_icon(true)
		"BLOCK_ME":
			_style_cell(COLOR_BLUE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, Color.BLACK)
			_update_inner_border(Color(0, 0, 0, 0))
			_update_block_bar(block_colors, cell_size_for_block)
		"BLOCK_OPPONENT":
			_style_cell(COLOR_ORANGE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, Color.BLACK)
			_update_inner_border(Color(0, 0, 0, 0))
			_update_block_bar(block_colors, cell_size_for_block)
		_:
			_style_cell(COLOR_WHITE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, Color.BLACK)
			_update_inner_border(Color(0, 0, 0, 0))


func shake() -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_valid():
		_shake_tween.kill()
	pivot_offset = custom_minimum_size / 2.0 if custom_minimum_size != Vector2.ZERO else Vector2(15, 15)
	modulate = Color(1, 0.35, 0.35, 1)
	scale = Vector2.ONE
	_shake_tween = create_tween()
	_shake_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_shake_tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.06)
	_shake_tween.tween_property(self, "scale", Vector2(0.97, 0.97), 0.06)
	_shake_tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.06)
	_shake_tween.tween_property(self, "scale", Vector2.ONE, 0.07)
	_shake_tween.parallel().tween_property(self, "modulate", COLOR_WHITE, 0.25)


func animate_reveal(next_state_callable: Callable) -> void:
	pivot_offset = custom_minimum_size / 2.0 if custom_minimum_size != Vector2.ZERO else Vector2(15, 15)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(0.0, 1.0), 0.075)
	tween.tween_callback(next_state_callable)
	tween.tween_property(self, "scale", Vector2.ONE, 0.075)


func pulse_word() -> void:
	pivot_offset = custom_minimum_size / 2.0 if custom_minimum_size != Vector2.ZERO else Vector2(15, 15)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.22, 1.22), 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 1), 0.25)


func pop_trap() -> void:
	_update_trap_icon(false)
	var temp := Control.new()
	temp.name = "TempTrapReveal"
	temp.set_anchors_preset(Control.PRESET_FULL_RECT)
	temp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	temp.modulate.a = 0.0
	temp.scale = Vector2(0.5, 0.5)
	temp.pivot_offset = Vector2(15, 15)
	add_child(temp)
	var icon := TextureRect.new()
	icon.texture = _trap_texture()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	temp.add_child(icon)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(temp, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(temp, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(temp, "scale", Vector2.ONE, 0.3)
	tween.tween_interval(1.1)
	tween.tween_property(temp, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(temp, "scale", Vector2(0.8, 0.8), 0.4)
	tween.tween_callback(temp.queue_free)


func break_block() -> void:
	pivot_offset = custom_minimum_size / 2.0 if custom_minimum_size != Vector2.ZERO else Vector2(15, 15)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)


func _style_cell(background: Color, state_shadow_color: Color, font: Color, border_color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border_color
	style.border_width_left = CELL_BORDER_WIDTH
	style.border_width_top = CELL_BORDER_WIDTH
	style.border_width_right = CELL_BORDER_WIDTH
	style.border_width_bottom = CELL_BORDER_WIDTH
	style.set_corner_radius_all(CELL_CORNER_RADIUS)
	style.shadow_color = state_shadow_color
	style.shadow_size = 0 if state_shadow_color.a == 0 else 3
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("pressed", style)
	add_theme_stylebox_override("disabled", style)
	add_theme_stylebox_override("focus", style)
	add_theme_color_override("font_color", font)
	add_theme_color_override("font_hover_color", font)
	add_theme_color_override("font_pressed_color", font)
	add_theme_color_override("font_disabled_color", font)
	add_theme_color_override("font_focus_color", font)


func _update_inner_border(inner_color: Color) -> void:
	if _inner_border == null:
		_inner_border = get_node_or_null("InnerBorder") as Control
	if _inner_border == null:
		return
	for child in _inner_border.get_children():
		child.queue_free()
	if inner_color.a == 0:
		_inner_border.visible = false
		return
	_inner_border.visible = true
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 2
	panel.offset_top = 2
	panel.offset_right = -2
	panel.offset_bottom = -2
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = inner_color
	style.border_width_left = CELL_BORDER_WIDTH
	style.border_width_top = CELL_BORDER_WIDTH
	style.border_width_right = CELL_BORDER_WIDTH
	style.border_width_bottom = CELL_BORDER_WIDTH
	style.set_corner_radius_all(CELL_INNER_CORNER_RADIUS)
	panel.add_theme_stylebox_override("panel", style)
	_inner_border.add_child(panel)


func _update_diagonal_split(color_a: Color, color_b: Color) -> void:
	if _diagonal_split == null:
		_diagonal_split = get_node_or_null("DiagonalSplit") as Control
	if _diagonal_split == null:
		return
	for child in _diagonal_split.get_children():
		child.queue_free()
	_diagonal_split.visible = true
	_diagonal_split.show_behind_parent = true
	_diagonal_split.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_diagonal_split.clip_contents = true
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = _diagonal_material(color_a, color_b)
	_diagonal_split.add_child(rect)


func _diagonal_material(color_a: Color, color_b: Color) -> ShaderMaterial:
	var key := "diag_%s_%s" % [color_a.to_html(false), color_b.to_html(false)]
	var cached = _icon_cache.get(key)
	if cached is ShaderMaterial:
		return cached
	var mat := ShaderMaterial.new()
	mat.shader = _diagonal_shader
	mat.set_shader_parameter("color_a", color_a)
	mat.set_shader_parameter("color_b", color_b)
	mat.set_shader_parameter("radius", 5.0)
	_icon_cache[key] = mat
	return mat


func _update_trap_icon(show: bool) -> void:
	if _trap_icon == null:
		_trap_icon = get_node_or_null("TrapIcon") as Control
	if _trap_icon == null:
		return
	for child in _trap_icon.get_children():
		child.queue_free()
	_trap_icon.visible = show
	if not show:
		return
	var icon := TextureRect.new()
	icon.texture = _trap_texture()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.stretch_mode = TextureRect.STRETCH_SCALE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trap_icon.add_child(icon)


func _trap_texture() -> Texture2D:
	if _icon_cache.has("TRAP_CELL"):
		return _icon_cache["TRAP_CELL"]
	var texture := load(TRAP_CELL_ICON_PATH) as Texture2D
	_icon_cache["TRAP_CELL"] = texture
	return texture


func _update_block_bar(colors: Array, cell_w: float) -> void:
	if _block_bar == null:
		_block_bar = get_node_or_null("BlockBar") as Control
	if _block_bar == null:
		return
	for child in _block_bar.get_children():
		child.queue_free()
	_block_bar.visible = true
	var d: int = clampi(int((cell_w if cell_w > 1.0 else 30.0) * 0.20), 7, 8)
	var sep := 2
	var corner := 8
	var center_wrapper := CenterContainer.new()
	center_wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_block_bar.add_child(center_wrapper)
	var bar := HBoxContainer.new()
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", sep)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_wrapper.add_child(bar)
	for i in BLOCK_BAR_SEGMENTS:
		var segment := Panel.new()
		segment.custom_minimum_size = Vector2(d, d)
		segment.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		segment.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var s_style := StyleBoxFlat.new()
		s_style.bg_color = colors[i] if i < colors.size() else Color.WHITE
		s_style.border_color = Color.BLACK
		s_style.border_width_left = 2
		s_style.border_width_top = 2
		s_style.border_width_right = 2
		s_style.border_width_bottom = 2
		s_style.set_corner_radius_all(corner)
		segment.add_theme_stylebox_override("panel", s_style)
		bar.add_child(segment)


func _clear_all_layers() -> void:
	for layer_name in ["TrapIcon", "BlockBar", "DiagonalSplit", "InnerBorder"]:
		var layer := get_node_or_null(layer_name) as Control
		if layer == null:
			continue
		for child in layer.get_children():
			child.queue_free()
		layer.visible = false
		if layer_name == "InnerBorder":
			continue
		if layer_name == "DiagonalSplit":
			layer.show_behind_parent = false
			layer.clip_contents = false


func set_cell_enabled(enabled: bool) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
