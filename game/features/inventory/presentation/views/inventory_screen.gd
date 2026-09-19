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

const PALETTE: Array = [
	Color(0.42, 0.23, 0.55),
	Color(0.45, 0.68, 0.16),
	Color(0.36, 0.68, 0.88),
	Color(0.55, 0.6, 0.68),
	Color(0.5, 0.28, 0.62),
	Color(0.62, 0.84, 0.84),
	Color(0.85, 0.62, 0.42),
	Color(0.9, 0.5, 0.2),
]

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
		Vector2(170, 58),
		Vector2(150, 50),
		16,
		14
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
		Vector2(72, 48),
		Vector2(60, 42),
		12,
		10
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
	font_inactive: int
) -> Button:
	var btn := Button.new()
	btn.name = "%sTab" % tab_id
	btn.set_meta("tab_id", tab_id)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = TAB_BLUE if active else TAB_GREEN
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = NAVY
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.custom_minimum_size = min_active if active else min_inactive
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	btn.add_child(margin)
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
		var label := _make_tab_label(title, HORIZONTAL_ALIGNMENT_LEFT, font_active if active else font_inactive)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
	else:
		margin.add_child(_make_tab_label(title, HORIZONTAL_ALIGNMENT_CENTER, font_active if active else font_inactive))
	return btn


func _make_tab_label(title: String, alignment: HorizontalAlignment, font_size: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.text = title
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 3)
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


func _page_count() -> int:
	if _view_model == null:
		return 1
	var total: int = _current_items().size()
	return maxi(1, int(ceil(float(total) / float(PAGE_SIZE))))


func _page_items() -> Array:
	if _view_model == null:
		return []
	return _current_items().slice(_page * PAGE_SIZE, _page * PAGE_SIZE + PAGE_SIZE)


func _card_color(item: InventoryItem) -> Color:
	if PALETTE.is_empty():
		return TAB_GREEN
	var index: int = absi(item.item_id.hash()) % PALETTE.size()
	return PALETTE[index] as Color


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
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sb := StyleBoxFlat.new()
	sb.bg_color = _card_color(item)
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
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
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
		initial.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		initial.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		initial.add_theme_constant_override("outline_size", 6)
		initial.add_theme_font_size_override("font_size", 44)
		initial.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.add_child(initial)
	var name_label := Label.new()
	name_label.text = item.name.strip_edges()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	name_label.add_theme_constant_override("outline_size", 5)
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.anchor_left = 0.0
	name_label.anchor_top = 1.0
	name_label.anchor_right = 1.0
	name_label.anchor_bottom = 1.0
	name_label.offset_left = 2
	name_label.offset_top = -30
	name_label.offset_right = -2
	name_label.offset_bottom = -4
	btn.add_child(name_label)
	if not _is_cosmetics() and item.quantity > 0:
		btn.add_child(_make_badge("x%d" % item.quantity))
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


func _make_card_frame(highlighted: bool, ring_color: Color) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.name = "CardFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.border_width_left = 5 if highlighted else 3
	ring.border_width_top = 5 if highlighted else 3
	ring.border_width_right = 5 if highlighted else 3
	ring.border_width_bottom = 5 if highlighted else 3
	ring.border_color = ring_color
	ring.corner_radius_top_left = CARD_CORNER_RADIUS
	ring.corner_radius_top_right = CARD_CORNER_RADIUS
	ring.corner_radius_bottom_right = CARD_CORNER_RADIUS
	ring.corner_radius_bottom_left = CARD_CORNER_RADIUS
	frame.add_theme_stylebox_override("panel", ring)
	return frame


func _make_equip_button(item: InventoryItem) -> Button:
	var eq := Button.new()
	eq.name = "EquipBtn"
	eq.set_meta("item_id", item.item_id)
	eq.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
	eq_sb.corner_radius_top_left = 10
	eq_sb.corner_radius_top_right = 10
	eq_sb.corner_radius_bottom_right = 10
	eq_sb.corner_radius_bottom_left = 10
	eq.add_theme_stylebox_override("normal", eq_sb)
	eq.add_theme_stylebox_override("hover", eq_sb)
	eq.add_theme_stylebox_override("pressed", eq_sb)
	eq.add_theme_stylebox_override("disabled", eq_sb)
	eq.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	eq.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	eq.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	eq.add_theme_constant_override("outline_size", 3)
	eq.add_theme_font_size_override("font_size", 13)
	eq.anchor_left = 0.5
	eq.anchor_top = 0.5
	eq.anchor_right = 0.5
	eq.anchor_bottom = 0.5
	eq.offset_left = -46
	eq.offset_top = -18
	eq.offset_right = 46
	eq.offset_bottom = 18
	if not locked:
		eq.pressed.connect(_on_equip_pressed.bind(item.item_id))
	return eq


func _make_badge(text: String) -> PanelContainer:
	var badge := PanelContainer.new()
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
	badge.offset_left = -46
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
	badge_label.add_theme_font_size_override("font_size", 13)
	badge.add_child(badge_label)
	return badge


func _make_download_button(item: InventoryItem) -> Button:
	var dl := Button.new()
	dl.name = "DownloadBtn"
	dl.set_meta("item_id", item.item_id)
	dl.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
	dl_sb.corner_radius_top_left = 10
	dl_sb.corner_radius_top_right = 10
	dl_sb.corner_radius_bottom_right = 10
	dl_sb.corner_radius_bottom_left = 10
	dl.add_theme_stylebox_override("normal", dl_sb)
	dl.add_theme_stylebox_override("hover", dl_sb)
	dl.add_theme_stylebox_override("pressed", dl_sb)
	dl.add_theme_stylebox_override("disabled", dl_sb)
	dl.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
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
	dl.offset_right = 44
	dl.offset_bottom = 40
	if not downloading:
		dl.pressed.connect(_on_download_pressed.bind(item.item_id))
	return dl


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
	_refresh_grid()


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
