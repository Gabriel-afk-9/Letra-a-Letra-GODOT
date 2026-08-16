extends PanelContainer
class_name PlayerCard

enum CardState { CLEAR, SEARCHING, LOCAL, OPPONENT }

@export_group("Card Styles")
@export var local_style: StyleBoxFlat
@export var opponent_style: StyleBoxFlat
@export var searching_style: StyleBoxFlat

@export_group("Avatar Styles")
@export var local_avatar_style: StyleBoxFlat
@export var opponent_avatar_style: StyleBoxFlat
@export var searching_avatar_style: StyleBoxFlat

@onready var avatar_frame: PanelContainer = %AvatarFrame
@onready var avatar: TextureRect = %AvatarTexture
@onready var spinner: Spinner = %Spinner
@onready var nickname: Label = %NicknameLabel

var _current_state: CardState = CardState.CLEAR

const INVENTORY_SIZE := 5

const POWER_ICON_PATHS: Dictionary = {
	"FREEZE": "res://assets/images/powers/freeze.png",
	"UNFREEZE": "res://assets/images/powers/unfreeze.png",
	"BLIND": "res://assets/images/powers/blind.png",
	"LANTERN": "res://assets/images/powers/lantern.png",
	"IMMUNITY": "res://assets/images/powers/imunity.png",
	"DETECT_TRAPS": "res://assets/images/powers/detecttraps.png",
	"BLOCK": "res://assets/images/powers/block.png",
	"UNBLOCK": "res://assets/images/powers/unblock.png",
	"SPY": "res://assets/images/powers/spy.png",
	"TRAP": "res://assets/images/powers/trap.png"
}

var _inventory_slots: Array = []
var _inventory_row: HBoxContainer = null
var _icon_cache: Dictionary = {}


func clear() -> void:
	_set_state(CardState.CLEAR)


func show_searching() -> void:
	_set_state(CardState.SEARCHING)


func show_local(player_name: String, avatar_texture: Texture2D = null) -> void:
	nickname.text = player_name
	if avatar_texture:
		avatar.texture = avatar_texture
	_set_state(CardState.LOCAL)


func show_opponent(player_name: String, avatar_texture: Texture2D = null) -> void:
	nickname.text = player_name
	if avatar_texture:
		avatar.texture = avatar_texture
	_set_state(CardState.OPPONENT)


func _set_state(new_state: CardState) -> void:
	_current_state = new_state

	match _current_state:
		CardState.CLEAR:
			hide()
			spinner.status = Spinner.Status.EMPTY

		CardState.SEARCHING:
			show()
			spinner.show()
			avatar.hide()
			nickname.text = "......"
			_apply_style(searching_style, searching_avatar_style)
			spinner.status = Spinner.Status.SPINNING

		CardState.LOCAL:
			show()
			spinner.hide()
			avatar.show()
			_apply_style(local_style, local_avatar_style)
			spinner.status = Spinner.Status.EMPTY

		CardState.OPPONENT:
			show()
			spinner.hide()
			avatar.show()
			_apply_style(opponent_style, opponent_avatar_style)
			spinner.status = Spinner.Status.EMPTY


func _apply_style(
	card_style: StyleBoxFlat,
	avatar_style: StyleBoxFlat
) -> void:
	if card_style:
		add_theme_stylebox_override("panel", card_style)

	if avatar_style:
		avatar_frame.add_theme_stylebox_override("panel", avatar_style)


# Inventário — exibição de leitura dos 5 slots. O card é compartilhado
# (home/matchmaking usam a mesma cena com overrides de path), então os slots
# NÃO são adicionados à cena: a fileira é montada em runtime apenas quando
# set_inventory() é chamado, preservando as outras telas intactas.

func set_inventory(inventory: Array) -> void:
	_ensure_inventory_row()

	for index in INVENTORY_SIZE:
		var slot_variant = _inventory_slots[index]

		if not slot_variant is TextureRect:
			continue

		var slot: TextureRect = slot_variant
		var power = inventory[index] if index < inventory.size() else null

		if power is GamePower:
			slot.texture = _power_icon(power.type)
			slot.tooltip_text = power.type
			slot.show()
		else:
			slot.texture = null
			slot.tooltip_text = ""
			slot.hide()


func _ensure_inventory_row() -> void:
	if _inventory_row != null:
		return

	var margin := get_node("MarginContainer")
	var header: Control = margin.get_child(0)

	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)

	margin.remove_child(header)
	wrapper.add_child(header)

	margin.add_child(wrapper)

	_inventory_row = HBoxContainer.new()
	_inventory_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_inventory_row.add_theme_constant_override("separation", 4)
	wrapper.add_child(_inventory_row)

	for index in INVENTORY_SIZE:
		var slot := TextureRect.new()
		slot.custom_minimum_size = Vector2(24, 24)
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.hide()
		_inventory_row.add_child(slot)
		_inventory_slots.append(slot)


func _power_icon(power_type: String) -> Texture2D:
	if _icon_cache.has(power_type):
		return _icon_cache[power_type]

	var path = POWER_ICON_PATHS.get(power_type)

	if path == null:
		return null

	var texture := load(str(path)) as Texture2D
	_icon_cache[power_type] = texture

	return texture
