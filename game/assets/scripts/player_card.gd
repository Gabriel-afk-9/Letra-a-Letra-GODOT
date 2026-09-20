extends PanelContainer
class_name PlayerCard

enum CardState { CLEAR, SEARCHING, LOCAL, OPPONENT }
enum BottomMode { NONE, STATS, POWERS }

@export_group("Card Styles")
@export var local_style: StyleBoxFlat
@export var opponent_style: StyleBoxFlat
@export var searching_style: StyleBoxFlat

@export_group("Avatar Styles")
@export var local_avatar_style: StyleBoxFlat
@export var opponent_avatar_style: StyleBoxFlat
@export var searching_avatar_style: StyleBoxFlat

@export var bottom_mode: BottomMode = BottomMode.NONE

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

const DOT_FILLED_BG := Color(1, 1, 1, 0.95)
const DOT_EMPTY_BG := Color(0.5, 0.5, 0.5, 0.6)

var _inventory_slots: Array = []
var _inventory_row: HBoxContainer = null
var _icon_cache: Dictionary = {}
var _power_dots: Array = []
var _has_stats_meta: bool = false


func _ready() -> void:
	_collect_power_dots()
	_apply_bottom_mode()


func _collect_power_dots() -> void:
	var row: HBoxContainer = get_node_or_null("MarginContainer/CardVBox/PowerDotsRow") as HBoxContainer
	if row == null:
		return
	_power_dots = row.get_children()


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


func set_bottom_mode(mode: BottomMode) -> void:
	bottom_mode = mode
	_apply_bottom_mode()


func set_stats_raw(wins: int, streak: int, matches: int, has_stats: bool = true) -> void:
	_has_stats_meta = has_stats
	var stats_pill: Control = get_node_or_null("MarginContainer/CardVBox/StatsPill") as Control
	if stats_pill == null:
		return
	var wins_label: Label = get_node_or_null("MarginContainer/CardVBox/StatsPill/StatsMargin/StatsRow/WinsBox/WinsValue") as Label
	var streak_label: Label = get_node_or_null("MarginContainer/CardVBox/StatsPill/StatsMargin/StatsRow/StreakBox/StreakValue") as Label
	var matches_label: Label = get_node_or_null("MarginContainer/CardVBox/StatsPill/StatsMargin/StatsRow/MatchesBox/MatchesValue") as Label
	if has_stats:
		if wins_label:
			wins_label.text = str(wins)
		if streak_label:
			streak_label.text = str(streak)
		if matches_label:
			matches_label.text = str(matches)
	else:
		if wins_label:
			wins_label.text = "-"
		if streak_label:
			streak_label.text = "-"
		if matches_label:
			matches_label.text = "-"
	bottom_mode = BottomMode.STATS
	_apply_bottom_mode()


func set_stats_from_profile(profile: HomePlayerProfile) -> void:
	if profile == null:
		set_stats_raw(0, 0, 0, false)
		return
	set_stats_raw(profile.wins, profile.streak, profile.matches, true)


func set_stats_from_player(player: MatchmakingPlayer) -> void:
	if player == null:
		set_stats_raw(0, 0, 0, false)
		return
	set_stats_raw(player.wins, player.streak, player.matches, player.has_stats)


func set_power_dots(inventory: Array) -> void:
	bottom_mode = BottomMode.POWERS
	_apply_bottom_mode()
	_update_power_dots(inventory)


func clear_bottom() -> void:
	bottom_mode = BottomMode.NONE
	_apply_bottom_mode()


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

	_apply_bottom_mode()


func _apply_bottom_mode() -> void:
	var stats_pill: Control = get_node_or_null("MarginContainer/CardVBox/StatsPill") as Control
	var dots_row: Control = get_node_or_null("MarginContainer/CardVBox/PowerDotsRow") as Control
	if stats_pill == null and dots_row == null:
		return
	var effective := bottom_mode
	if _current_state == CardState.SEARCHING or _current_state == CardState.CLEAR:
		effective = BottomMode.NONE
	if stats_pill:
		stats_pill.visible = effective == BottomMode.STATS
	if dots_row:
		dots_row.visible = effective == BottomMode.POWERS


func _apply_style(
	card_style: StyleBoxFlat,
	avatar_style: StyleBoxFlat
) -> void:
	if card_style:
		add_theme_stylebox_override("panel", card_style)

	if avatar_style:
		avatar_frame.add_theme_stylebox_override("panel", avatar_style)



func set_inventory(inventory: Array) -> void:
	if _power_dots.size() > 0 or get_node_or_null("MarginContainer/CardVBox/PowerDotsRow") != null:
		set_power_dots(inventory)
		return
	_ensure_legacy_inventory_row()

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


func _ensure_legacy_inventory_row() -> void:
	if _inventory_row != null:
		return

	var margin := get_node_or_null("MarginContainer") as MarginContainer
	if margin == null:
		return
	if margin.get_child_count() == 0:
		return
	var header: Control = margin.get_child(0) as Control
	if header == null:
		return
	if header.name == "CardVBox":
		return

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


func _count_occupied(inventory: Array) -> int:
	var occupied := 0
	for power in inventory:
		if power is GamePower:
			occupied += 1
	return occupied


func _update_power_dots(inventory: Array) -> void:
	if _power_dots.is_empty():
		_collect_power_dots()
	if _power_dots.is_empty():
		return
	var occupied := _count_occupied(inventory)
	for index in _power_dots.size():
		var dot_variant = _power_dots[index]
		if not dot_variant is Panel:
			continue
		var dot: Panel = dot_variant
		var was_occupied: bool = dot.has_meta("occupied") and bool(dot.get_meta("occupied"))
		var is_occupied: bool = index < occupied
		dot.set_meta("occupied", is_occupied)
		if is_occupied and not was_occupied:
			_ensure_dot_style(dot, DOT_FILLED_BG)
			_pulse_dot(dot)
		elif not is_occupied and was_occupied:
			_ensure_dot_style(dot, DOT_FILLED_BG)
			_fade_dot(dot)
		else:
			var bg := DOT_FILLED_BG if is_occupied else DOT_EMPTY_BG
			_ensure_dot_style(dot, bg)


func _ensure_dot_style(dot: Panel, bg: Color) -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color.BLACK
	style.bg_color = bg
	dot.add_theme_stylebox_override("panel", style)
	dot.scale = Vector2.ONE
	dot.modulate = Color.WHITE


func _pulse_dot(dot: Panel) -> void:
	dot.pivot_offset = dot.size / 2.0
	if dot.size == Vector2.ZERO:
		dot.pivot_offset = Vector2(8, 8)
	if dot.has_meta("dot_tween"):
		var old = dot.get_meta("dot_tween")
		if old is Tween and old.is_valid():
			old.kill()
	var tween := create_tween()
	dot.set_meta("dot_tween", tween)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(dot, "scale", Vector2(1.45, 1.45), 0.16)
	tween.tween_property(dot, "scale", Vector2.ONE, 0.22)
	tween.parallel().tween_property(dot, "modulate", Color(1, 0.9, 0.4, 1), 0.16)
	tween.parallel().tween_property(dot, "modulate", Color.WHITE, 0.22)
	var dot_id_pulse := dot.get_instance_id()
	var tween_id_pulse := tween.get_instance_id()
	tween.finished.connect(func() -> void:
		var d: Control = instance_from_id(dot_id_pulse) as Control
		if not is_instance_valid(d):
			return
		if not d.has_meta("dot_tween"):
			return
		var cur: Variant = d.get_meta("dot_tween")
		if cur == null or not is_instance_valid(cur as Object):
			d.remove_meta("dot_tween")
			return
		if (cur as Object).get_instance_id() != tween_id_pulse:
			return
		d.remove_meta("dot_tween")
	)


func _fade_dot(dot: Panel) -> void:
	dot.pivot_offset = dot.size / 2.0
	if dot.size == Vector2.ZERO:
		dot.pivot_offset = Vector2(8, 8)
	if dot.has_meta("dot_tween"):
		var old = dot.get_meta("dot_tween")
		if old is Tween and old.is_valid():
			old.kill()
	var style := dot.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		style = StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color.BLACK
		style.bg_color = DOT_FILLED_BG
		dot.add_theme_stylebox_override("panel", style)
	var tween := create_tween()
	dot.set_meta("dot_tween", tween)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(dot, "scale", Vector2(0.85, 0.85), 0.18)
	tween.tween_property(dot, "scale", Vector2.ONE, 0.12)
	tween.parallel().tween_property(style, "bg_color", DOT_EMPTY_BG, 0.18)
	var dot_id_fade := dot.get_instance_id()
	var tween_id_fade := tween.get_instance_id()
	tween.finished.connect(func() -> void:
		var d: Control = instance_from_id(dot_id_fade) as Control
		if not is_instance_valid(d):
			return
		if not d.has_meta("dot_tween"):
			return
		var cur: Variant = d.get_meta("dot_tween")
		if cur == null or not is_instance_valid(cur as Object):
			d.remove_meta("dot_tween")
			return
		if (cur as Object).get_instance_id() != tween_id_fade:
			return
		d.remove_meta("dot_tween")
	)


func _power_icon(power_type: String) -> Texture2D:
	if _icon_cache.has(power_type):
		return _icon_cache[power_type]

	var path = POWER_ICON_PATHS.get(power_type)

	if path == null:
		return null

	var texture := load(str(path)) as Texture2D
	_icon_cache[power_type] = texture

	return texture
