extends HubPage
class_name InventoryScreen

const PAGE_SIZE := 12
const NAVY := Color(0.118, 0.165, 0.267)
const TAB_BLUE := Color(0.16, 0.6, 0.85)
const TAB_GREEN := Color(0.2, 0.72, 0.42)
const SELECT_ORANGE := Color(0.96, 0.51, 0.12)

const TAB_TITLES := {
	"AVATAR": "AVATAR",
	"BANNER": "BANNER",
	"FRAME": "MOLDURA",
	"EMOTE": "EMOTE",
	"BOARD": "TABULEIRO",
	"CELL": "CÉLULA",
}

const SECTION_TITLES := {
	"COSMETICS": "COSMÉTICOS",
	"OTHERS": "OUTROS",
}

const SECTION_ICONS := {
	"COSMETICS": preload("res://assets/images/icons/room-icon.png"),
	"OTHERS": preload("res://assets/images/icons/navbar-2.png"),
}

const TAB_ICON_FALLBACK := preload("res://assets/images/icons/navbar-2.png")
const CARD_MASK_SHADER := preload("res://assets/styles/rounded_image_mask.gdshader")
const CARD_CORNER_RADIUS := 16

const CARD_BG := Color(0.094, 0.129, 0.196)
const CARD_BAR_BG := Color(0.043, 0.063, 0.11, 0.92)
const TAB_IDLE_BG := Color(0.286, 0.337, 0.427)
const CHIP_IDLE_BG := Color(0.796, 0.843, 0.886)
const CHIP_ACTIVE_BG := Color(1, 1, 1)
const FOCUS_RING_COLOR := Color(0.96, 0.51, 0.12)

const NAME_BAR_HEIGHT := 34
const CARD_BORDER := 3
const CARD_BORDER_HIGHLIGHT := 5

const BASE_MARGIN_LEFT := 14
const BASE_MARGIN_TOP := 10
const BASE_MARGIN_RIGHT := 14
const BASE_MARGIN_BOTTOM := 8

@onready var _content: MarginContainer = $Content
@onready var _count_label: Label = $Content/MainVBox/Header/HeaderRow/CountPill/CountLabel
@onready var _tabs_row: HBoxContainer = $Content/MainVBox/TabScroll/TabsRow
@onready var _sub_tabs_row: HBoxContainer = $Content/MainVBox/Panel/PanelMargin/PanelVBox/SubTabsRow
@onready var _grid: GridContainer = $Content/MainVBox/Panel/PanelMargin/PanelVBox/ItemGrid
@onready var _status_label: Label = $Content/MainVBox/Panel/PanelMargin/PanelVBox/StatusLabel
@onready var _page_label: Label = $Content/MainVBox/Panel/PanelMargin/PanelVBox/PagerRow/PagePill/PageMargin/PageLabel
@onready var _prev_btn: Button = $Content/MainVBox/Panel/PanelMargin/PanelVBox/PagerRow/PrevBtn
@onready var _next_btn: Button = $Content/MainVBox/Panel/PanelMargin/PanelVBox/PagerRow/NextBtn

var _view_model: InventoryViewModel
var _assets_node: Node
var _image_material: ShaderMaterial
var _section: String = ""
var _category: String = ""
var _page: int = 0
var _selected: Dictionary = {}


func page_id() -> StringName:
	return &"inventory"


func enter(_params: Dictionary) -> void:
	if not is_node_ready() or _view_model == null:
		return
	_view_model.load_initial()
	_focus_default_control()


func bind_view_model(vm: InventoryViewModel) -> void:
	if vm == null or vm == _view_model:
		return
	_disconnect_view_model()
	if _assets_node != null and is_instance_valid(_assets_node):
		if _assets_node.is_inside_tree():
			remove_child(_assets_node)
		_assets_node.queue_free()
	_assets_node = null
	_view_model = vm
	_assets_node = _view_model.asset_service()
	if _assets_node != null and is_node_ready():
		add_child(_assets_node)
	_section = ""
	_category = ""
	_page = 0
	_selected.clear()
	if not is_node_ready():
		return
	_connect_view_model()
	_refresh_all()


func _ready() -> void:
	if _view_model == null:
		_view_model = InventoryFactory.create()
	_assets_node = _view_model.asset_service()
	if _assets_node != null and not _assets_node.is_inside_tree():
		add_child(_assets_node)
	_connect_view_model()
	_prev_btn.pressed.connect(_on_prev_pressed)
	_next_btn.pressed.connect(_on_next_pressed)
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)
	_refresh_all()


func _connect_view_model() -> void:
	if _view_model == null:
		return
	if not _view_model.inventory_changed.is_connected(_refresh_all):
		_view_model.inventory_changed.connect(_refresh_all)
	if not _view_model.asset_changed.is_connected(_on_asset_changed):
		_view_model.asset_changed.connect(_on_asset_changed)
	if not _view_model.download_changed.is_connected(_on_download_changed):
		_view_model.download_changed.connect(_on_download_changed)
	if not _view_model.action_changed.is_connected(_on_action_changed):
		_view_model.action_changed.connect(_on_action_changed)
	if not _view_model.loading_changed.is_connected(_on_loading_changed):
		_view_model.loading_changed.connect(_on_loading_changed)
	if not _view_model.error_changed.is_connected(_on_error_changed):
		_view_model.error_changed.connect(_on_error_changed)


func _disconnect_view_model() -> void:
	if _view_model == null:
		return
	if _view_model.inventory_changed.is_connected(_refresh_all):
		_view_model.inventory_changed.disconnect(_refresh_all)
	if _view_model.asset_changed.is_connected(_on_asset_changed):
		_view_model.asset_changed.disconnect(_on_asset_changed)
	if _view_model.download_changed.is_connected(_on_download_changed):
		_view_model.download_changed.disconnect(_on_download_changed)
	if _view_model.action_changed.is_connected(_on_action_changed):
		_view_model.action_changed.disconnect(_on_action_changed)
	if _view_model.loading_changed.is_connected(_on_loading_changed):
		_view_model.loading_changed.disconnect(_on_loading_changed)
	if _view_model.error_changed.is_connected(_on_error_changed):
		_view_model.error_changed.disconnect(_on_error_changed)


func _apply_safe_area() -> void:
	var window_size := DisplayServer.window_get_size()
	var viewport_size := get_viewport_rect().size
	if window_size.x <= 0 or window_size.y <= 0:
		return
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return
	var window_rect := Rect2i(Vector2i.ZERO, window_size)
	var safe := DisplayServer.get_display_safe_area().intersection(window_rect)
	if safe.size.x <= 0 or safe.size.y <= 0:
		return
	var scale_x := viewport_size.x / float(window_size.x)
	var scale_y := viewport_size.y / float(window_size.y)
	var inset_left := int(round(safe.position.x * scale_x))
	var inset_top := int(round(safe.position.y * scale_y))
	var inset_right := int(round((window_size.x - safe.end.x) * scale_x))
	var inset_bottom := int(round((window_size.y - safe.end.y) * scale_y))
	_content.add_theme_constant_override("margin_left", BASE_MARGIN_LEFT + inset_left)
	_content.add_theme_constant_override("margin_top", BASE_MARGIN_TOP + inset_top)
	_content.add_theme_constant_override("margin_right", BASE_MARGIN_RIGHT + inset_right)
	_content.add_theme_constant_override("margin_bottom", BASE_MARGIN_BOTTOM + inset_bottom)


func _focus_default_control() -> void:
	await get_tree().process_frame
	if not is_visible_in_tree():
		return
	if _grid.get_child_count() > 0:
		var first := _grid.get_child(0) as Control
		if first != null:
			first.grab_focus()
			return
	if _tabs_row.get_child_count() > 0:
		var tab := _tabs_row.get_child(0) as Control
		if tab != null:
			tab.grab_focus()


func _refresh_all() -> void:
	if _view_model == null:
		return
	var sections: Array = _view_model.sections()
	if _section.is_empty() or not sections.has(_section):
		_section = str(sections[0])
		_page = 0
	var categories: Array = _view_model.cosmetic_categories()
	if _category.is_empty() or not categories.has(_category):
		_category = str(categories[0])
		_page = 0
	_refresh_sections()
	_refresh_sub_tabs()
	_refresh_grid()
	_refresh_pager()
	_refresh_status()
	_refresh_count()


func _is_cosmetics() -> bool:
	return _view_model != null and _view_model.is_cosmetics_section(_section)


func _filter_id() -> String:
	if _is_cosmetics():
		return _category
	return _section


func _current_items() -> Array:
	if _view_model == null:
		return []
	if _is_cosmetics():
		return _view_model.cosmetic_items(_category)
	return _view_model.other_items()


func _refresh_sections() -> void:
	for child in _tabs_row.get_children():
		_tabs_row.remove_child(child)
		child.queue_free()
	for section_variant in _view_model.sections():
		_tabs_row.add_child(_make_section_tab(str(section_variant)))


func _refresh_sub_tabs() -> void:
	for child in _sub_tabs_row.get_children():
		_sub_tabs_row.remove_child(child)
		child.queue_free()
	_sub_tabs_row.visible = _is_cosmetics()
	if not _is_cosmetics():
		return
	for category_variant in _view_model.cosmetic_categories():
		_sub_tabs_row.add_child(_make_category_tab(str(category_variant)))


func _make_section_tab(section_id: String) -> Button:
	var active: bool = section_id == _section
	var btn := _build_tab_button(
		section_id,
		str(SECTION_TITLES.get(section_id, section_id)),
		SECTION_ICONS.get(section_id, TAB_ICON_FALLBACK),
		active,
		Vector2(168, 58),
		Vector2(146, 46),
		15,
		13,
		TAB_BLUE,
		TAB_IDLE_BG,
		Color(1, 1, 1, 1),
		Color(1, 1, 1, 0.85),
		true
	)
	btn.pressed.connect(_on_section_pressed.bind(section_id))
	return btn


func _make_category_tab(category_id: String) -> Button:
	var active: bool = category_id == _category
	var btn := _build_tab_button(
		category_id,
		str(TAB_TITLES.get(category_id, category_id)),
		null,
		active,
		Vector2(0, 42),
		Vector2(0, 42),
		11,
		11,
		CHIP_ACTIVE_BG,
		CHIP_IDLE_BG,
		NAVY,
		Color(0.294, 0.353, 0.443),
		false,
		SELECT_ORANGE
	)
	btn.pressed.connect(_on_category_pressed.bind(category_id))
	return btn


func _build_tab_button(
	tab_id: String,
	title: String,
	icon_texture: Texture2D,
	active: bool,
	min_active: Vector2,
	min_inactive: Vector2,
	font_active: int,
	font_inactive: int,
	bg_active: Color,
	bg_inactive: Color,
	text_active: Color,
	text_inactive: Color,
	joined_bottom: bool,
	active_border: Color = NAVY
) -> Button:
	var btn := Button.new()
	btn.name = "%sTab" % tab_id
	btn.set_meta("tab_id", tab_id)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.clip_contents = true
	btn.focus_mode = Control.FOCUS_ALL
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_active if active else bg_inactive
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = active_border if active else NAVY
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_right = 0 if joined_bottom and active else 16
	sb.corner_radius_bottom_left = 0 if joined_bottom and active else 16
	if active:
		sb.shadow_color = Color(0, 0, 0, 0.3)
		sb.shadow_size = 5
		sb.shadow_offset = Vector2(0, 3)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.add_theme_stylebox_override("focus", _focus_style(FOCUS_RING_COLOR))
	btn.custom_minimum_size = min_active if active else min_inactive
	if min_active.x <= 0.0 and min_inactive.x <= 0.0:
		var font := get_theme_default_font()
		var font_size: int = font_active if active else font_inactive
		var text_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		btn.custom_minimum_size = Vector2(text_width + 20.0, btn.custom_minimum_size.y)
	if not active:
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 4)
	btn.add_child(margin)
	var text_color := text_active if active else text_inactive
	if icon_texture != null:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		margin.add_child(row)
		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.custom_minimum_size = Vector2(26, 26)
		icon.texture = icon_texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon)
		var label := _make_tab_label(title, HORIZONTAL_ALIGNMENT_LEFT, font_active if active else font_inactive, text_color)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
	else:
		margin.add_child(_make_tab_label(title, HORIZONTAL_ALIGNMENT_CENTER, font_active if active else font_inactive, text_color))
	return btn


func _make_tab_label(title: String, alignment: HorizontalAlignment, font_size: int, text_color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.text = title
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _refresh_grid() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	if _view_model == null:
		return
	for item_variant in _page_items():
		var item := item_variant as InventoryItem
		if item != null:
			_grid.add_child(_make_card(item))


func _refresh_pager() -> void:
	if _view_model != null and _view_model.is_loading():
		_page_label.text = "Carregando..."
		_prev_btn.disabled = true
		_next_btn.disabled = true
		return
	var pages := _page_count()
	_page_label.text = "Pág %d" % (_page + 1)
	_prev_btn.disabled = _page <= 0
	_next_btn.disabled = _page >= pages - 1


func _refresh_status() -> void:
	if _view_model == null:
		return
	if _view_model.is_loading():
		_status_label.text = "Carregando inventário..."
	elif _view_model.load_failed():
		if _view_model.error_message().is_empty():
			_status_label.text = "Não foi possível carregar o inventário."
		else:
			_status_label.text = _view_model.error_message()
	elif _view_model.has_error():
		_status_label.text = _view_model.error_message()
	elif not _view_model.has_items():
		_status_label.text = "Nenhum item por aqui ainda."
	elif _page_items().is_empty():
		_status_label.text = "Nada nesta seção."
	else:
		_status_label.text = ""
	_status_label.visible = not _status_label.text.is_empty()


func _refresh_count() -> void:
	var total := _current_items().size()
	if total == 1:
		_count_label.text = "1 ITEM"
	else:
		_count_label.text = "%d ITENS" % total


func _page_count() -> int:
	if _view_model == null:
		return 1
	var total: int = _current_items().size()
	return maxi(1, int(ceil(float(total) / float(PAGE_SIZE))))


func _page_items() -> Array:
	if _view_model == null:
		return []
	return _current_items().slice(_page * PAGE_SIZE, _page * PAGE_SIZE + PAGE_SIZE)


func _make_card(item: InventoryItem) -> Button:
	var is_selected: bool = str(_selected.get(_filter_id(), "")) == item.item_id
	var highlighted: bool = item.equipped or is_selected
	var ring_color := NAVY
	if item.equipped:
		ring_color = TAB_GREEN
	elif is_selected:
		ring_color = SELECT_ORANGE
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(96, 122)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.focus_mode = Control.FOCUS_ALL
	btn.set_meta("item_id", item.item_id)
	btn.set_meta("item", item)
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_BG
	sb.corner_radius_top_left = CARD_CORNER_RADIUS
	sb.corner_radius_top_right = CARD_CORNER_RADIUS
	sb.corner_radius_bottom_right = CARD_CORNER_RADIUS
	sb.corner_radius_bottom_left = CARD_CORNER_RADIUS
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	btn.add_theme_stylebox_override("focus", _focus_style(FOCUS_RING_COLOR))
	var texture := _view_model.texture_for(item)
	if texture != null:
		var art := TextureRect.new()
		art.texture = texture
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.material = _card_image_material()
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.add_child(art)
	else:
		var initial := Label.new()
		initial.mouse_filter = Control.MOUSE_FILTER_IGNORE
		initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var clean_name := item.name.strip_edges()
		if clean_name.is_empty():
			initial.text = "?"
		else:
			initial.text = clean_name.left(1).to_upper()
		initial.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
		initial.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		initial.add_theme_constant_override("outline_size", 6)
		initial.add_theme_font_size_override("font_size", 44)
		initial.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.add_child(initial)
	var overlay := _make_focus_overlay()
	btn.add_child(overlay)
	btn.focus_entered.connect(func() -> void: overlay.visible = true)
	btn.focus_exited.connect(func() -> void: overlay.visible = false)
	btn.add_child(_make_name_bar(item))
	if not _is_cosmetics() and item.quantity > 0:
		btn.add_child(_make_badge("x%d" % item.quantity))
	if item.equipped:
		btn.add_child(_make_equipped_chip())
	if _view_model.needs_download(item):
		btn.add_child(_make_download_button(item))
	if _is_cosmetics() and is_selected and not item.equipped:
		btn.add_child(_make_equip_button(item))
	btn.add_child(_make_card_frame(highlighted, ring_color))
	btn.pressed.connect(_on_item_pressed.bind(item.item_id))
	return btn


func _card_image_material() -> ShaderMaterial:
	if _image_material == null or not is_instance_valid(_image_material):
		_image_material = ShaderMaterial.new()
		_image_material.shader = CARD_MASK_SHADER
	return _image_material


func _make_name_bar(item: InventoryItem) -> PanelContainer:
	var bar := PanelContainer.new()
	bar.name = "NameBar"
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.anchor_left = 0.0
	bar.anchor_top = 1.0
	bar.anchor_right = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = 0
	bar.offset_top = -NAME_BAR_HEIGHT
	bar.offset_right = 0
	bar.offset_bottom = 0
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_BAR_BG
	sb.corner_radius_bottom_right = CARD_CORNER_RADIUS
	sb.corner_radius_bottom_left = CARD_CORNER_RADIUS
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 2.0
	sb.content_margin_bottom = 2.0
	bar.add_theme_stylebox_override("panel", sb)
	var name_label := Label.new()
	name_label.text = item.name.strip_edges()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_label.add_theme_font_size_override("font_size", 13)
	bar.add_child(name_label)
	return bar


func _make_focus_overlay() -> PanelContainer:
	var ring := PanelContainer.new()
	ring.name = "FocusOverlay"
	ring.visible = false
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = FOCUS_RING_COLOR
	sb.set_corner_radius_all(CARD_CORNER_RADIUS + 2)
	sb.expand_margin_left = 3.0
	sb.expand_margin_top = 3.0
	sb.expand_margin_right = 3.0
	sb.expand_margin_bottom = 3.0
	ring.add_theme_stylebox_override("panel", sb)
	return ring


func _make_card_frame(highlighted: bool, ring_color: Color) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.name = "CardFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_theme_stylebox_override("panel", _card_frame_style(highlighted, ring_color))
	return frame


func _card_frame_style(highlighted: bool, ring_color: Color) -> StyleBoxFlat:
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.border_width_left = CARD_BORDER_HIGHLIGHT if highlighted else CARD_BORDER
	ring.border_width_top = CARD_BORDER_HIGHLIGHT if highlighted else CARD_BORDER
	ring.border_width_right = CARD_BORDER_HIGHLIGHT if highlighted else CARD_BORDER
	ring.border_width_bottom = CARD_BORDER_HIGHLIGHT if highlighted else CARD_BORDER
	ring.border_color = ring_color
	ring.corner_radius_top_left = CARD_CORNER_RADIUS
	ring.corner_radius_top_right = CARD_CORNER_RADIUS
	ring.corner_radius_bottom_right = CARD_CORNER_RADIUS
	ring.corner_radius_bottom_left = CARD_CORNER_RADIUS
	return ring


func _make_equip_button(item: InventoryItem) -> Button:
	var eq := Button.new()
	eq.name = "EquipBtn"
	eq.set_meta("item_id", item.item_id)
	eq.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	eq.focus_mode = Control.FOCUS_ALL
	var busy: bool = _view_model.is_equip_busy(item)
	var locked: bool = not _view_model.action_id().is_empty()
	if busy:
		eq.text = "..."
	else:
		eq.text = "EQUIPAR"
	eq.disabled = locked
	var eq_sb := StyleBoxFlat.new()
	eq_sb.bg_color = TAB_GREEN
	eq_sb.border_width_left = 2
	eq_sb.border_width_top = 2
	eq_sb.border_width_right = 2
	eq_sb.border_width_bottom = 2
	eq_sb.border_color = NAVY
	eq_sb.corner_radius_top_left = 12
	eq_sb.corner_radius_top_right = 12
	eq_sb.corner_radius_bottom_right = 12
	eq_sb.corner_radius_bottom_left = 12
	eq_sb.shadow_color = Color(0, 0, 0, 0.35)
	eq_sb.shadow_size = 4
	eq_sb.shadow_offset = Vector2(0, 2)
	var eq_hover := eq_sb.duplicate() as StyleBoxFlat
	eq_hover.bg_color = TAB_GREEN.lightened(0.12)
	var eq_pressed := eq_sb.duplicate() as StyleBoxFlat
	eq_pressed.bg_color = TAB_GREEN.darkened(0.15)
	var eq_disabled := eq_sb.duplicate() as StyleBoxFlat
	eq_disabled.bg_color = Color(0.62, 0.65, 0.7)
	eq.add_theme_stylebox_override("normal", eq_sb)
	eq.add_theme_stylebox_override("hover", eq_hover)
	eq.add_theme_stylebox_override("pressed", eq_pressed)
	eq.add_theme_stylebox_override("disabled", eq_disabled)
	eq.add_theme_stylebox_override("focus", _focus_style(TAB_GREEN))
	eq.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	eq.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	eq.add_theme_constant_override("outline_size", 3)
	eq.add_theme_font_size_override("font_size", 12)
	eq.anchor_left = 0.5
	eq.anchor_top = 1.0
	eq.anchor_right = 0.5
	eq.anchor_bottom = 1.0
	eq.offset_left = -40
	eq.offset_top = -NAME_BAR_HEIGHT - 40
	eq.offset_right = 40
	eq.offset_bottom = -NAME_BAR_HEIGHT - 6
	if not locked:
		eq.pressed.connect(_on_equip_pressed.bind(item.item_id))
	return eq


func _make_equipped_chip() -> PanelContainer:
	var chip := PanelContainer.new()
	chip.name = "EquippedChip"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.anchor_left = 1.0
	chip.anchor_top = 0.0
	chip.anchor_right = 1.0
	chip.anchor_bottom = 0.0
	chip.offset_left = -74
	chip.offset_top = 6
	chip.offset_right = -6
	chip.offset_bottom = 28
	var sb := StyleBoxFlat.new()
	sb.bg_color = TAB_GREEN
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = NAVY
	sb.set_corner_radius_all(10)
	chip.add_theme_stylebox_override("panel", sb)
	var chip_label := Label.new()
	chip_label.text = "EQUIPADO"
	chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	chip_label.add_theme_font_size_override("font_size", 10)
	chip.add_child(chip_label)
	return chip


func _make_badge(text: String) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.name = "QuantityBadge"
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = SELECT_ORANGE
	badge_sb.border_width_left = 2
	badge_sb.border_width_top = 2
	badge_sb.border_width_right = 2
	badge_sb.border_width_bottom = 2
	badge_sb.border_color = NAVY
	badge_sb.corner_radius_top_left = 10
	badge_sb.corner_radius_top_right = 10
	badge_sb.corner_radius_bottom_right = 10
	badge_sb.corner_radius_bottom_left = 10
	badge.add_theme_stylebox_override("panel", badge_sb)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.anchor_left = 1.0
	badge.anchor_top = 0.0
	badge.anchor_right = 1.0
	badge.anchor_bottom = 0.0
	badge.offset_left = -42
	badge.offset_top = 6
	badge.offset_right = -6
	badge.offset_bottom = 30
	var badge_label := Label.new()
	badge_label.text = text
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	badge_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	badge_label.add_theme_constant_override("outline_size", 3)
	badge_label.add_theme_font_size_override("font_size", 12)
	badge.add_child(badge_label)
	return badge


func _make_download_button(item: InventoryItem) -> Button:
	var dl := Button.new()
	dl.name = "DownloadBtn"
	dl.set_meta("item_id", item.item_id)
	dl.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	dl.focus_mode = Control.FOCUS_ALL
	var downloading: bool = _view_model.is_downloading(item)
	if downloading:
		dl.text = "..."
		dl.disabled = true
	else:
		dl.text = "↓"
		dl.disabled = false
	var dl_sb := StyleBoxFlat.new()
	dl_sb.bg_color = SELECT_ORANGE
	dl_sb.border_width_left = 2
	dl_sb.border_width_top = 2
	dl_sb.border_width_right = 2
	dl_sb.border_width_bottom = 2
	dl_sb.border_color = NAVY
	dl_sb.set_corner_radius_all(18)
	dl_sb.shadow_color = Color(0, 0, 0, 0.35)
	dl_sb.shadow_size = 4
	dl_sb.shadow_offset = Vector2(0, 2)
	var dl_hover := dl_sb.duplicate() as StyleBoxFlat
	dl_hover.bg_color = SELECT_ORANGE.lightened(0.12)
	var dl_disabled := dl_sb.duplicate() as StyleBoxFlat
	dl_disabled.bg_color = Color(0.62, 0.65, 0.7)
	dl.add_theme_stylebox_override("normal", dl_sb)
	dl.add_theme_stylebox_override("hover", dl_hover)
	dl.add_theme_stylebox_override("pressed", dl_sb)
	dl.add_theme_stylebox_override("disabled", dl_disabled)
	dl.add_theme_stylebox_override("focus", _focus_style(SELECT_ORANGE))
	dl.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	dl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	dl.add_theme_constant_override("outline_size", 3)
	dl.add_theme_font_size_override("font_size", 18)
	dl.anchor_left = 0.0
	dl.anchor_top = 0.0
	dl.anchor_right = 0.0
	dl.anchor_bottom = 0.0
	dl.offset_left = 6
	dl.offset_top = 6
	dl.offset_right = 42
	dl.offset_bottom = 42
	if not downloading:
		dl.pressed.connect(_on_download_pressed.bind(item.item_id))
	return dl


func _focus_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = color
	sb.set_corner_radius_all(16)
	sb.expand_margin_left = 3.0
	sb.expand_margin_top = 3.0
	sb.expand_margin_right = 3.0
	sb.expand_margin_bottom = 3.0
	return sb


func _find_item(item_id: String) -> InventoryItem:
	if _view_model == null:
		return null
	for item_variant in _view_model.items():
		var item := item_variant as InventoryItem
		if item != null and item.item_id == item_id:
			return item
	return null


func _on_section_pressed(section_id: String) -> void:
	_section = section_id
	_page = 0
	_refresh_all()


func _on_category_pressed(category_id: String) -> void:
	_category = category_id
	_page = 0
	_refresh_all()


func _on_prev_pressed() -> void:
	_page = maxi(0, _page - 1)
	_refresh_grid()
	_refresh_pager()


func _on_next_pressed() -> void:
	_page = mini(_page_count() - 1, _page + 1)
	_refresh_grid()
	_refresh_pager()


func _on_item_pressed(item_id: String) -> void:
	_selected[_filter_id()] = item_id
	_update_card_selection()


func _update_card_selection() -> void:
	for card in _grid.get_children():
		var item := card.get_meta("item", null) as InventoryItem
		if item == null:
			continue
		var is_selected: bool = str(_selected.get(_filter_id(), "")) == item.item_id
		var highlighted: bool = item.equipped or is_selected
		var ring_color := NAVY
		if item.equipped:
			ring_color = TAB_GREEN
		elif is_selected:
			ring_color = SELECT_ORANGE
		var frame := card.get_node_or_null("CardFrame") as PanelContainer
		if frame != null:
			frame.add_theme_stylebox_override("panel", _card_frame_style(highlighted, ring_color))
		var equip_btn := card.get_node_or_null("EquipBtn") as Button
		var wants_equip: bool = _is_cosmetics() and is_selected and not item.equipped
		if wants_equip and equip_btn == null:
			var btn := _make_equip_button(item)
			card.add_child(btn)
			card.move_child(btn, card.get_child_count() - 2)
			if card.has_focus():
				btn.grab_focus()
		elif not wants_equip and equip_btn != null:
			card.remove_child(equip_btn)
			equip_btn.queue_free()


func _on_download_pressed(item_id: String) -> void:
	var item := _find_item(item_id)
	if item == null:
		return
	_view_model.download_asset(item)


func _on_equip_pressed(item_id: String) -> void:
	var item := _find_item(item_id)
	if item == null:
		return
	_view_model.equip_item(item)


func _on_asset_changed(_item_id: String) -> void:
	_refresh_grid()


func _on_download_changed(_item_id: String) -> void:
	_refresh_grid()


func _on_action_changed(_action_id: String) -> void:
	_refresh_grid()


func _on_loading_changed(_is_loading: bool) -> void:
	_refresh_pager()
	_refresh_status()


func _on_error_changed(_message: String) -> void:
	_refresh_status()
