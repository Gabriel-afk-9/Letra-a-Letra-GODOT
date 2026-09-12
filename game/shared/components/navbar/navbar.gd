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

@onready var shop_label: Label = $NavMargin/NavRow/NavShopBtn/ShopBox/ShopLabel
@onready var items_label: Label = $NavMargin/NavRow/NavItemsBtn/ItemsBox/ItemsLabel
@onready var play_label: Label = $NavMargin/NavRow/NavPlayBtn/PlayTile/PlayTileMargin/PlayBox/PlayLabel
@onready var social_label: Label = $NavMargin/NavRow/NavSocialBtn/SocialBox/SocialLabel
@onready var rooms_label: Label = $NavMargin/NavRow/NavRoomsBtn/RoomsBox/RoomsLabel

var _buttons: Dictionary = {}
var _labels: Dictionary = {}

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
	for page_id in _buttons:
		var btn: Button = _buttons[page_id]
		btn.pressed.connect(_on_nav_pressed.bind(page_id))
	set_selected(PAGE_PLAY)

func set_selected(page_id: StringName) -> void:
	for key in _labels:
		var label: Label = _labels[key]
		label.add_theme_color_override("font_color", LABEL_ACTIVE if key == page_id else LABEL_INACTIVE)

func set_page_enabled(page_id: StringName, enabled: bool) -> void:
	if _buttons.has(page_id):
		(_buttons[page_id] as Button).disabled = not enabled

func _on_nav_pressed(page_id: StringName) -> void:
	page_selected.emit(page_id)
