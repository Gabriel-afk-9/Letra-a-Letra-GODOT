extends HubPage
class_name InventoryScreen

enum Category { AVATAR, FRAME, EMOTE, CONSUMABLE }

const PAGE_SIZE := 12
const NAVY := Color(0.118, 0.165, 0.267)
const TAB_BLUE := Color(0.16, 0.6, 0.85)
const TAB_GREEN := Color(0.2, 0.72, 0.42)
const SELECT_ORANGE := Color(0.96, 0.51, 0.12)

const ART_AVATAR_1 := preload("res://assets/images/avatars/avatar-1.png")
const ART_AVATAR_2 := preload("res://assets/images/avatars/avatar-2.png")
const ART_AVATAR_3 := preload("res://assets/images/avatars/avatar-3.png")
const ART_GIRL := preload("res://assets/images/avatars/little_girl_transparent.png")
const ART_OLD_MAN := preload("res://assets/images/avatars/old_man_avatar_tranparent.png")
const ART_LOGO := preload("res://assets/cosmetics/avatar/logo.png")
const ART_STUPID := preload("res://assets/cosmetics/avatar/stupid.png")
const ART_PIE := preload("res://assets/cosmetics/avatar/pie.png")
const ART_EVIL := preload("res://assets/cosmetics/avatar/evil.png")
const ART_ARVENIS := preload("res://assets/cosmetics/avatar/arvenis.png")
const ART_FRAME := preload("res://assets/cosmetics/frame/test.png")
const ART_FREEZE := preload("res://assets/images/powers/freeze.png")
const ART_TRAP := preload("res://assets/images/powers/trap.png")
const ART_IMUNITY := preload("res://assets/images/powers/imunity.png")
const ART_LANTERN := preload("res://assets/images/powers/lantern.png")
const ART_BLIND := preload("res://assets/images/powers/blind.png")
const ART_SPY := preload("res://assets/images/powers/spy.png")
const ART_DETECT := preload("res://assets/images/powers/detecttraps.png")
const ART_BLOCK := preload("res://assets/images/powers/block.png")

@onready var _grid: GridContainer = $Content/MainVBox/Panel/PanelMargin/PanelVBox/ItemGrid
@onready var _page_label: Label = $Content/MainVBox/Panel/PanelMargin/PanelVBox/PagerRow/PagePill/PageMargin/PageLabel
@onready var _prev_btn: Button = $Content/MainVBox/Panel/PanelMargin/PanelVBox/PagerRow/PrevBtn
@onready var _next_btn: Button = $Content/MainVBox/Panel/PanelMargin/PanelVBox/PagerRow/NextBtn
@onready var _tab_buttons: Array = [
	$Content/MainVBox/TabsRow/AvatarTab,
	$Content/MainVBox/TabsRow/FrameTab,
	$Content/MainVBox/TabsRow/EmoteTab,
	$Content/MainVBox/TabsRow/ConsumableTab,
]

var _category: int = Category.AVATAR
var _page: int = 0
var _catalog: Dictionary = {}
var _equipped: Dictionary = {}
var _selected: Dictionary = {}


func page_id() -> StringName:
	return &"inventory"


func enter(_params: Dictionary) -> void:
	if not is_node_ready():
		return
	_refresh()


func _ready() -> void:
	_build_catalog()
	for i in _tab_buttons.size():
		(_tab_buttons[i] as Button).pressed.connect(_on_tab_pressed.bind(i))
	_prev_btn.pressed.connect(_on_prev_pressed)
	_next_btn.pressed.connect(_on_next_pressed)
	_refresh()


func _build_catalog() -> void:
	_catalog[Category.AVATAR] = [
		{"id": "avatar_1", "name": "AVATAR 1", "art": ART_STUPID, "bg": Color(0.42, 0.23, 0.55), "qty": 0, "locked": false},
		{"id": "avatar_2", "name": "BANNER 1", "art": ART_LANTERN, "bg": Color(0.45, 0.68, 0.16), "qty": 0, "locked": false},
		{"id": "avatar_3", "name": "AVATAR 3", "art": ART_ARVENIS, "bg": Color(0.36, 0.68, 0.88), "qty": 0, "locked": false},
		{"id": "avatar_5", "name": "AVATAR 5", "art": ART_EVIL, "bg": Color(0.55, 0.6, 0.68), "qty": 0, "locked": false},
		{"id": "avatar_6", "name": "AVATAR 6", "art": ART_PIE, "bg": Color(0.5, 0.28, 0.62), "qty": 0, "locked": false},
		{"id": "avatar_7", "name": "AVATAR 7", "art": ART_OLD_MAN, "bg": Color(0.62, 0.84, 0.84), "qty": 0, "locked": false},
		{"id": "avatar_8", "name": "AVATAR 8", "art": ART_AVATAR_1, "bg": Color(0.85, 0.62, 0.42), "qty": 0, "locked": false},
		{"id": "avatar_9", "name": "AVATAR 9", "art": ART_AVATAR_2, "bg": Color(0.62, 0.56, 0.4), "qty": 0, "locked": false},
		{"id": "avatar_10", "name": "AVATAR 10", "art": ART_AVATAR_3, "bg": Color(0.56, 0.42, 0.28), "qty": 0, "locked": false},
		{"id": "avatar_11", "name": "AVATAR 11", "art": ART_LOGO, "bg": Color(0.16, 0.36, 0.42), "qty": 0, "locked": false},
		{"id": "avatar_12", "name": "AVATAR 12", "art": ART_GIRL, "bg": Color(0.56, 0.84, 0.74), "qty": 0, "locked": false},
		{"id": "avatar_13", "name": "AVATAR 13", "art": ART_TRAP, "bg": Color(0.9, 0.5, 0.2), "qty": 0, "locked": false},
		{"id": "avatar_14", "name": "AVATAR 14", "art": ART_ARVENIS, "bg": Color(0.3, 0.5, 0.7), "qty": 0, "locked": false},
		{"id": "avatar_15", "name": "AVATAR 15", "art": ART_PIE, "bg": Color(0.7, 0.45, 0.3), "qty": 0, "locked": false},
		{"id": "avatar_16", "name": "AVATAR 16", "art": ART_EVIL, "bg": Color(0.35, 0.35, 0.45), "qty": 0, "locked": false},
		{"id": "avatar_17", "name": "AVATAR 17", "art": ART_AVATAR_1, "bg": Color(0.5, 0.7, 0.5), "qty": 0, "locked": false},
		{"id": "avatar_18", "name": "AVATAR 18", "art": ART_AVATAR_2, "bg": Color(0.5, 0.5, 0.55), "qty": 0, "locked": true},
		{"id": "avatar_19", "name": "AVATAR 19", "art": ART_GIRL, "bg": Color(0.8, 0.7, 0.55), "qty": 0, "locked": false},
	]
	_catalog[Category.FRAME] = [
		{"id": "frame_1", "name": "MOLDURA 1", "art": ART_FRAME, "bg": Color(0.36, 0.68, 0.88), "qty": 0, "locked": false},
		{"id": "frame_2", "name": "MOLDURA 2", "art": ART_LOGO, "bg": Color(0.5, 0.28, 0.62), "qty": 0, "locked": false},
		{"id": "frame_3", "name": "MOLDURA 3", "art": ART_FRAME, "bg": Color(0.45, 0.68, 0.16), "qty": 0, "locked": false},
		{"id": "frame_4", "name": "MOLDURA 4", "art": ART_PIE, "bg": Color(0.9, 0.5, 0.2), "qty": 0, "locked": false},
		{"id": "frame_5", "name": "MOLDURA 5", "art": ART_FRAME, "bg": Color(0.55, 0.6, 0.68), "qty": 0, "locked": false},
		{"id": "frame_6", "name": "MOLDURA 6", "art": ART_ARVENIS, "bg": Color(0.16, 0.5, 0.5), "qty": 0, "locked": false},
		{"id": "frame_7", "name": "MOLDURA 7", "art": ART_FRAME, "bg": Color(0.56, 0.42, 0.28), "qty": 0, "locked": false},
		{"id": "frame_8", "name": "MOLDURA 8", "art": ART_AVATAR_3, "bg": Color(0.4, 0.45, 0.55), "qty": 0, "locked": true},
	]
	_catalog[Category.EMOTE] = [
		{"id": "emote_1", "name": "EMOTE 1", "art": ART_BLIND, "bg": Color(0.42, 0.23, 0.55), "qty": 0, "locked": false},
		{"id": "emote_2", "name": "EMOTE 2", "art": ART_SPY, "bg": Color(0.36, 0.68, 0.88), "qty": 0, "locked": false},
		{"id": "emote_3", "name": "EMOTE 3", "art": ART_FREEZE, "bg": Color(0.62, 0.84, 0.84), "qty": 0, "locked": false},
		{"id": "emote_4", "name": "EMOTE 4", "art": ART_LANTERN, "bg": Color(0.85, 0.62, 0.42), "qty": 0, "locked": false},
		{"id": "emote_5", "name": "EMOTE 5", "art": ART_TRAP, "bg": Color(0.9, 0.5, 0.2), "qty": 0, "locked": false},
		{"id": "emote_6", "name": "EMOTE 6", "art": ART_IMUNITY, "bg": Color(0.45, 0.68, 0.16), "qty": 0, "locked": false},
		{"id": "emote_7", "name": "EMOTE 7", "art": ART_DETECT, "bg": Color(0.5, 0.28, 0.62), "qty": 0, "locked": false},
		{"id": "emote_8", "name": "EMOTE 8", "art": ART_BLOCK, "bg": Color(0.55, 0.6, 0.68), "qty": 0, "locked": false},
		{"id": "emote_9", "name": "EMOTE 9", "art": ART_EVIL, "bg": Color(0.4, 0.45, 0.55), "qty": 0, "locked": true},
	]
	_catalog[Category.CONSUMABLE] = [
		{"id": "cons_1", "name": "GELO", "art": ART_FREEZE, "bg": Color(0.62, 0.84, 0.84), "qty": 3, "locked": false},
		{"id": "cons_2", "name": "ARMADILHA", "art": ART_TRAP, "bg": Color(0.9, 0.5, 0.2), "qty": 2, "locked": false},
		{"id": "cons_3", "name": "ESCUDO", "art": ART_IMUNITY, "bg": Color(0.36, 0.68, 0.88), "qty": 1, "locked": false},
		{"id": "cons_4", "name": "LANTERNA", "art": ART_LANTERN, "bg": Color(0.85, 0.62, 0.42), "qty": 5, "locked": false},
		{"id": "cons_5", "name": "CEGUEIRA", "art": ART_BLIND, "bg": Color(0.42, 0.23, 0.55), "qty": 2, "locked": false},
		{"id": "cons_6", "name": "ESPIÃO", "art": ART_SPY, "bg": Color(0.5, 0.28, 0.62), "qty": 4, "locked": false},
		{"id": "cons_7", "name": "RADAR", "art": ART_DETECT, "bg": Color(0.45, 0.68, 0.16), "qty": 1, "locked": false},
		{"id": "cons_8", "name": "BLOQUEIO", "art": ART_BLOCK, "bg": Color(0.55, 0.6, 0.68), "qty": 2, "locked": false},
	]
	_equipped[Category.AVATAR] = "avatar_1"
	_equipped[Category.FRAME] = "frame_1"
	_equipped[Category.EMOTE] = "emote_1"
	_selected[Category.AVATAR] = "avatar_1"
	_selected[Category.FRAME] = "frame_1"
	_selected[Category.EMOTE] = "emote_1"
	_selected[Category.CONSUMABLE] = "cons_1"


func _refresh() -> void:
	if _catalog.is_empty():
		_build_catalog()
	_refresh_tabs()
	_refresh_grid()
	_refresh_pager()


func _refresh_tabs() -> void:
	for i in _tab_buttons.size():
		var btn := _tab_buttons[i] as Button
		var active: bool = i == _category
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
		btn.custom_minimum_size = Vector2(116, 56) if active else Vector2(96, 46)
		var box := btn.get_child(0)
		var icon := box.get_child(0) as TextureRect
		var label := box.get_child(1) as Label
		icon.custom_minimum_size = Vector2(30, 30) if active else Vector2(24, 24)
		label.add_theme_font_size_override("font_size", 20 if active else 12)


func _refresh_grid() -> void:
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for item in _page_items():
		_grid.add_child(_make_card(item))


func _refresh_pager() -> void:
	var pages := _page_count()
	_page_label.text = "Pág %d" % (_page + 1)
	_prev_btn.disabled = _page <= 0
	_next_btn.disabled = _page >= pages - 1


func _page_count() -> int:
	var total: int = (_catalog[_category] as Array).size()
	return maxi(1, int(ceil(float(total) / float(PAGE_SIZE))))


func _page_items() -> Array:
	var items: Array = _catalog[_category] as Array
	return items.slice(_page * PAGE_SIZE, _page * PAGE_SIZE + PAGE_SIZE)


func _make_card(item: Dictionary) -> Button:
	var highlighted: bool = String(_equipped.get(_category, "")) == String(item["id"]) or String(_selected.get(_category, "")) == String(item["id"])
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(96, 122)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var sb := StyleBoxFlat.new()
	sb.bg_color = item["bg"]
	sb.border_width_left = 5 if highlighted else 3
	sb.border_width_top = 5 if highlighted else 3
	sb.border_width_right = 5 if highlighted else 3
	sb.border_width_bottom = 5 if highlighted else 3
	if _category == Category.CONSUMABLE and highlighted:
		sb.border_color = SELECT_ORANGE
	elif highlighted:
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
	var art := TextureRect.new()
	art.texture = item["art"]
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.offset_left = 10
	art.offset_top = 6
	art.offset_right = -10
	art.offset_bottom = -28
	if bool(item["locked"]):
		art.modulate = Color(0.55, 0.55, 0.6, 1)
	btn.add_child(art)
	var name_label := Label.new()
	name_label.text = String(item["name"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
	if int(item["qty"]) > 0:
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
		badge_label.text = "x%d" % int(item["qty"])
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		badge_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		badge_label.add_theme_constant_override("outline_size", 3)
		badge_label.add_theme_font_size_override("font_size", 13)
		badge.add_child(badge_label)
		btn.add_child(badge)
	if bool(item["locked"]):
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.55)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.add_child(dim)
		var lock_label := Label.new()
		lock_label.text = "BLOQUEADO"
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		lock_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		lock_label.add_theme_constant_override("outline_size", 4)
		lock_label.add_theme_font_size_override("font_size", 13)
		lock_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.add_child(lock_label)
	btn.pressed.connect(_on_item_pressed.bind(String(item["id"])))
	return btn


func _on_tab_pressed(index: int) -> void:
	_category = index
	_page = 0
	_refresh()


func _on_prev_pressed() -> void:
	_page = maxi(0, _page - 1)
	_refresh_grid()
	_refresh_pager()


func _on_next_pressed() -> void:
	_page = mini(_page_count() - 1, _page + 1)
	_refresh_grid()
	_refresh_pager()


func _on_item_pressed(item_id: String) -> void:
	for item in (_catalog[_category] as Array):
		if String(item["id"]) == item_id and bool(item["locked"]):
			return
	if _category == Category.CONSUMABLE:
		_selected[_category] = item_id
	else:
		_equipped[_category] = item_id
		_selected[_category] = item_id
	_refresh_grid()
