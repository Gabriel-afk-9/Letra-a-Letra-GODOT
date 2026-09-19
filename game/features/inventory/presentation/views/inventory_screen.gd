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
	"CONSUMABLE": "CONSUMÍVEIS",
}

const TAB_ICONS := {
	"AVATAR": preload("res://assets/images/icons/icon-user.png"),
	"BANNER": preload("res://assets/images/icons/room-icon.png"),
	"FRAME": preload("res://assets/images/icons/room-icon.png"),
	"EMOTE": preload("res://assets/images/icons/bot-icon.png"),
	"CONSUMABLE": preload("res://assets/images/icons/navbar-2.png"),
}
const TAB_ICON_FALLBACK := preload("res://assets/images/icons/navbar-2.png")

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
@onready var _grid: GridContainer = $Content/MainVBox/Panel/PanelMargin/PanelVBox/ItemGrid
@onready var _status_label: Label = $Content/MainVBox/Panel/PanelMargin/PanelVBox/StatusLabel
@onready var _page_label: Label = $Content/MainVBox/Panel/PanelMargin/PanelVBox/PagerRow/PagePill/PageMargin/PageLabel
@onready var _prev_btn: Button = $Content/MainVBox/Panel/PanelMargin/PanelVBox/PagerRow/PrevBtn
@onready var _next_btn: Button = $Content/MainVBox/Panel/PanelMargin/PanelVBox/PagerRow/NextBtn

var _view_model: InventoryViewModel
var _assets_node: Node
var _tabs: Array = []
var _tab: String = ""
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
	_tab = ""
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
	if _view_model.loading_changed.is_connected(_on_loading_changed):
		_view_model.loading_changed.disconnect(_on_loading_changed)
	if _view_model.error_changed.is_connected(_on_error_changed):
		_view_model.error_changed.disconnect(_on_error_changed)


func _refresh_all() -> void:
	if _view_model == null:
		return
	_tabs = _view_model.categories()
	if _tab.is_empty() or not _tabs.has(_tab):
		if _tabs.is_empty():
			_tab = ""
		else:
			_tab = str(_tabs[0])
		_page = 0
	_refresh_tabs()
	_refresh_grid()
	_refresh_pager()
	_refresh_status()


func _refresh_tabs() -> void:
	for child in _tabs_row.get_children():
		_tabs_row.remove_child(child)
		child.queue_free()
	for tab_id_variant in _tabs:
		_tabs_row.add_child(_make_tab(str(tab_id_variant)))


func _make_tab(tab_id: String) -> Button:
	var active: bool = tab_id == _tab
	var btn := Button.new()
	btn.name = "%sTab" % tab_id
	btn.set_meta("tab_id", tab_id)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
	btn.custom_minimum_size = Vector2(104, 52) if active else Vector2(88, 44)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	btn.add_child(box)
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(28, 28) if active else Vector2(22, 22)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.texture = TAB_ICONS.get(tab_id, TAB_ICON_FALLBACK)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(icon)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text = str(TAB_TITLES.get(tab_id, tab_id))
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_font_size_override("font_size", 16 if active else 11)
	box.add_child(label)
	btn.pressed.connect(_on_tab_pressed.bind(tab_id))
	return btn


func _refresh_grid() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	if _tab.is_empty() or _view_model == null:
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
		_status_label.text = "Nada nesta aba."
	else:
		_status_label.text = ""


func _page_count() -> int:
	if _view_model == null or _tab.is_empty():
		return 1
	var total: int = _view_model.items_for(_tab).size()
	return maxi(1, int(ceil(float(total) / float(PAGE_SIZE))))


func _page_items() -> Array:
	if _view_model == null or _tab.is_empty():
		return []
	var items: Array = _view_model.items_for(_tab)
	return items.slice(_page * PAGE_SIZE, _page * PAGE_SIZE + PAGE_SIZE)


func _card_color(item: InventoryItem) -> Color:
	if PALETTE.is_empty():
		return TAB_GREEN
	var index: int = absi(item.item_id.hash()) % PALETTE.size()
	return PALETTE[index] as Color


func _make_card(item: InventoryItem) -> Button:
	var is_selected: bool = str(_selected.get(_tab, "")) == item.item_id
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(96, 122)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sb := StyleBoxFlat.new()
	sb.bg_color = _card_color(item)
	sb.border_width_left = 5 if (item.equipped or is_selected) else 3
	sb.border_width_top = 5 if (item.equipped or is_selected) else 3
	sb.border_width_right = 5 if (item.equipped or is_selected) else 3
	sb.border_width_bottom = 5 if (item.equipped or is_selected) else 3
	if is_selected:
		sb.border_color = SELECT_ORANGE
	elif item.equipped:
		sb.border_color = TAB_BLUE
	else:
		sb.border_color = NAVY
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_right = 16
	sb.corner_radius_bottom_left = 16
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
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.offset_left = 10
		art.offset_top = 6
		art.offset_right = -10
		art.offset_bottom = -28
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
		initial.offset_left = 10
		initial.offset_top = 6
		initial.offset_right = -10
		initial.offset_bottom = -28
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
	if _view_model.is_consumable_tab(_tab) and item.quantity > 0:
		btn.add_child(_make_badge("x%d" % item.quantity))
	if _view_model.needs_download(item):
		btn.add_child(_make_download_button(item))
	btn.pressed.connect(_on_item_pressed.bind(item.item_id))
	return btn


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


func _on_tab_pressed(tab_id: String) -> void:
	_tab = tab_id
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
	if _tab.is_empty():
		return
	_selected[_tab] = item_id
	_refresh_grid()


func _on_download_pressed(item_id: String) -> void:
	var item := _find_item(item_id)
	if item == null:
		return
	_view_model.download_asset(item)


func _on_asset_changed(_item_id: String) -> void:
	_refresh_grid()


func _on_download_changed(_item_id: String) -> void:
	_refresh_grid()


func _on_loading_changed(_is_loading: bool) -> void:
	_refresh_pager()
	_refresh_status()


func _on_error_changed(_message: String) -> void:
	_refresh_status()
