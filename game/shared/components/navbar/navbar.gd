extends PanelContainer
class_name Navbar

signal page_selected(page_id: StringName)

const PAGE_SHOP := &"shop"
const PAGE_INVENTORY := &"inventory"
const PAGE_PLAY := &"play"
const PAGE_SOCIAL := &"social"
const PAGE_ROOMS := &"rooms"

const LABEL_ACTIVE := Color(1, 1, 1, 1)
const LABEL_INACTIVE := Color(0.85, 0.89, 0.94, 1)

@onready var nav_shop_btn: Button = $NavMargin/NavRow/NavShopBtn
@onready var nav_items_btn: Button = $NavMargin/NavRow/NavItemsBtn
@onready var nav_play_btn: Button = $NavMargin/NavRow/NavPlayBtn
@onready var nav_social_btn: Button = $NavMargin/NavRow/NavSocialBtn
@onready var nav_rooms_btn: Button = $NavMargin/NavRow/NavRoomsBtn

@onready var shop_label: Label = $NavMargin/NavRow/NavShopBtn/ShopTile/ShopTileMargin/ShopBox/ShopLabel
@onready var items_label: Label = $NavMargin/NavRow/NavItemsBtn/ItemsTile/ItemsTileMargin/ItemsBox/ItemsLabel
@onready var play_label: Label = $NavMargin/NavRow/NavPlayBtn/PlayTile/PlayTileMargin/PlayBox/PlayLabel
@onready var social_label: Label = $NavMargin/NavRow/NavSocialBtn/SocialTile/SocialTileMargin/SocialBox/SocialLabel
@onready var rooms_label: Label = $NavMargin/NavRow/NavRoomsBtn/RoomsTile/RoomsTileMargin/RoomsBox/RoomsLabel

@onready var shop_tile: PanelContainer = $NavMargin/NavRow/NavShopBtn/ShopTile
@onready var items_tile: PanelContainer = $NavMargin/NavRow/NavItemsBtn/ItemsTile
@onready var play_tile: PanelContainer = $NavMargin/NavRow/NavPlayBtn/PlayTile
@onready var social_tile: PanelContainer = $NavMargin/NavRow/NavSocialBtn/SocialTile
@onready var rooms_tile: PanelContainer = $NavMargin/NavRow/NavRoomsBtn/RoomsTile

var _buttons: Dictionary = {}
var _labels: Dictionary = {}
var _tiles: Dictionary = {}
var _selected: StringName = PAGE_PLAY

func _ready() -> void:
	_buttons = {
		PAGE_SHOP: nav_shop_btn,
		PAGE_INVENTORY: nav_items_btn,
		PAGE_PLAY: nav_play_btn,
		PAGE_SOCIAL: nav_social_btn,
		PAGE_ROOMS: nav_rooms_btn,
	}
	_labels = {
		PAGE_SHOP: shop_label,
		PAGE_INVENTORY: items_label,
		PAGE_PLAY: play_label,
		PAGE_SOCIAL: social_label,
		PAGE_ROOMS: rooms_label,
	}
	_tiles = {
		PAGE_SHOP: shop_tile,
		PAGE_INVENTORY: items_tile,
		PAGE_PLAY: play_tile,
		PAGE_SOCIAL: social_tile,
		PAGE_ROOMS: rooms_tile,
	}
	for page_id in _buttons:
		var btn: Button = _buttons[page_id]
		btn.pressed.connect(_on_nav_pressed.bind(page_id))
	set_selected(PAGE_PLAY)

func selected_page() -> StringName:
	return _selected

func set_selected(page_id: StringName) -> void:
	_selected = page_id
	for key in _labels:
		var label: Label = _labels[key]
		var active: bool = key == page_id
		label.add_theme_color_override("font_color", LABEL_ACTIVE if active else LABEL_INACTIVE)
		_apply_tile(key, active)

func _apply_tile(page_id: StringName, active: bool) -> void:
	var tile: PanelContainer = _tiles[page_id]
	tile.add_theme_stylebox_override("panel", _active_tile_style() if active else _inactive_tile_style())
	tile.offset_top = -16.0 if active else 0.0

func _active_tile_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.329, 0.388, 0.478, 1)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_right = 10
	sb.corner_radius_bottom_left = 10
	return sb

func _inactive_tile_style() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()

func set_page_enabled(page_id: StringName, enabled: bool) -> void:
	if _buttons.has(page_id):
		(_buttons[page_id] as Button).disabled = not enabled

func _on_nav_pressed(page_id: StringName) -> void:
	page_selected.emit(page_id)
