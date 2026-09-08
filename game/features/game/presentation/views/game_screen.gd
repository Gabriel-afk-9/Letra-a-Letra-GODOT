extends Control
class_name GameScreen


const BOARD_SIZE := 10
const CELL_SIZE := Vector2(30, 30)

const COLOR_BLUE := Color(0.101960786, 0.57254905, 0.9019608, 1)
const COLOR_ORANGE := Color(0.9529412, 0.52156866, 0.09411765, 1)

const CELL_BORDER_WIDTH := 2
const CELL_CORNER_RADIUS := 5

const COLOR_WHITE := Color(1, 1, 1, 1)
const COLOR_NEON_GREEN := Color(0.2, 1.0, 0.4, 1)
const COLOR_HIDDEN_BORDER := Color(1, 1, 1, 0.6431373)
const COLOR_SPY_BORDER := Color(0.6, 0.6, 0.6, 1)
const COLOR_TEXT_DARK := Color(0.15, 0.15, 0.15, 1)
const COLOR_TEXT_NEUTRAL := Color(0.45, 0.45, 0.45, 1)

const CARD_FADE_DURATION := 0.2
const BOARD_PULSE_DURATION := 0.6
const BOARD_PULSE_MAX_SHADOW := 8
const GLOBAL_SWIPE_THRESHOLD_PX := 40.0
const BOARD_DIMMED_MODULATE := Color(1, 1, 1, 0.5)
const POWER_GRANT_FLASH_COLOR := Color(1, 0.85, 0.3, 1)
const POWER_GRANT_PULSE_DURATION := 0.16
const POWER_GRANT_SETTLE_DURATION := 0.24

const EFFECT_FREEZE_COLOR := Color(0.2, 0.5, 1.0, 0.25)
const EFFECT_IMMUNITY_COLOR := Color(1.0, 0.55, 0.1, 0.2)
const EFFECT_BLIND_COLOR := Color(0.0, 0.0, 0.0, 0.5)
const EFFECT_OVERLAY_FADE := 0.3
const COLOR_BLIND_BG := Color(0.05, 0.05, 0.05, 1)
const COLOR_BLIND_BORDER := Color(0.3, 0.3, 0.3, 1)
const EFFECT_LANTERN_FLASH := Color(1, 1, 1, 0.6)
const EFFECT_UNFREEZE_HOT := Color(1.0, 0.45, 0.15, 0.4)
const UNFREEZE_HOT_HOLD := 2.0
const TRAP_CELL_ICON_PATH := "res://assets/images/powers/trap-cell.png"
const TRAP_ICON_SIZE := Vector2(20, 20)
const BLOCK_BAR_SEGMENTS := 3
const BLOCK_BAR_EMPTY := Color(0.25, 0.25, 0.25, 1)
const TRAP_POP_SCALE := Vector2(1.3, 1.3)
const UNBLOCK_POP_SCALE := Vector2(1.2, 1.2)


@onready var my_card_wrapper: Control = $MarginContainer/MainLayout/TopBar/CardsCenter/MyCardWrapper
@onready var opponent_card_wrapper: Control = $MarginContainer/MainLayout/TopBar/CardsCenter/OpponentCardWrapper
@onready var my_player_card = $MarginContainer/MainLayout/TopBar/CardsCenter/MyCardWrapper/MyPlayerCard
@onready var my_power_dots: HBoxContainer = $MarginContainer/MainLayout/TopBar/CardsCenter/MyCardWrapper/MyPowerDots
@onready var opponent_player_card = $MarginContainer/MainLayout/TopBar/CardsCenter/OpponentCardWrapper/OpponentPlayerCard
@onready var opponent_power_dots: HBoxContainer = $MarginContainer/MainLayout/TopBar/CardsCenter/OpponentCardWrapper/OpponentPowerDots
@onready var turn_label: Label = $MarginContainer/MainLayout/TopBar/TurnLabel
@onready var words_container: HFlowContainer = $MarginContainer/MainLayout/WordsContainer
@onready var board_grid: GridContainer = $MarginContainer/MainLayout/BoardGrid
@onready var leave_button: Button = $TopBarLeaveButton
@onready var status_label: Label = $MarginContainer/MainLayout/StatusLabel
@onready var inventory_slot_1: TextureButton = $MarginContainer/MainLayout/InventoryPanel/InventoryContainer/InventorySlot1/Icon
@onready var inventory_slot_2: TextureButton = $MarginContainer/MainLayout/InventoryPanel/InventoryContainer/InventorySlot2/Icon
@onready var inventory_slot_3: TextureButton = $MarginContainer/MainLayout/InventoryPanel/InventoryContainer/InventorySlot3/Icon
@onready var inventory_slot_4: TextureButton = $MarginContainer/MainLayout/InventoryPanel/InventoryContainer/InventorySlot4/Icon
@onready var inventory_slot_5: TextureButton = $MarginContainer/MainLayout/InventoryPanel/InventoryContainer/InventorySlot5/Icon

var _view_model: GameViewModel
var _cell_buttons: Dictionary = {}
var _last_cell_state: Dictionary = {}
var _cards_fade_tween: Tween
var _pulse_tween: Tween
var _power_grant_tween: Tween
var _effect_tween: Tween
var _flash_tween: Tween
var _blind_tween: Tween

var _effect_overlay: ColorRect = null
var _blind_vignette: Control = null
var _was_blinded: bool = false
var _was_frozen: bool = false

var _board_wrapper: PanelContainer = null

var _global_power_armed: bool = false
var _action_locked: bool = false
var _armed_scope: String = ""

var _drag_start_y: float = 0.0
var _dragging_slot_index: int = -1

var _cached_is_my_turn: bool = false
var _cached_seconds_remaining: float = 0.0

var _my_nickname := ""
var _opponent_nickname := ""

var _cached_my_inventory: Array = []
var _power_seen_seq: Dictionary = {}
var _power_seq_counter: int = 0
var _cached_opponent_inventory: Array = []
var _inventory_slots: Array = []
var _my_dots: Array = []
var _opponent_dots: Array = []
var _icon_cache: Dictionary = {}

var _navigation_started: bool = false


func _ready() -> void:
	leave_button.pressed.connect(_on_leave_button_pressed)
	_inventory_slots = [
		inventory_slot_1,
		inventory_slot_2,
		inventory_slot_3,
		inventory_slot_4,
		inventory_slot_5,
	]
	_my_dots = my_power_dots.get_children()
	_opponent_dots = opponent_power_dots.get_children()
	
	words_container.alignment = FlowContainer.ALIGNMENT_CENTER
	words_container.add_theme_constant_override("h_separation", 12)
	words_container.add_theme_constant_override("v_separation", 10)
	
	_wrap_words_container()
	
	_wrap_board_grid()
	
	for i in _inventory_slots.size():
		var slot: TextureButton = _inventory_slots[i]
		slot.ignore_texture_size = true
		slot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		slot.pressed.connect(_on_power_slot_pressed.bind(i))
		slot.gui_input.connect(_on_inventory_icon_gui_input.bind(i))
	
	_shrink_game_cards()
	GameFactory.bind(self)


func _shrink_game_cards() -> void:
	for card in [my_player_card, opponent_player_card]:
		if card is PlayerCard:
			(card as PlayerCard).custom_minimum_size = Vector2(220, 70)
			var avatar_tex: TextureRect = (card as PlayerCard).get_node_or_null("%AvatarTexture") as TextureRect
			if avatar_tex:
				avatar_tex.custom_minimum_size = Vector2(60, 60)
			var spinner = (card as PlayerCard).get_node_or_null("%Spinner")
			if spinner is Control:
				(spinner as Control).custom_minimum_size = Vector2(60, 60)
			var margin_c := (card as PlayerCard).get_node_or_null("MarginContainer") as MarginContainer
			if margin_c:
				margin_c.add_theme_constant_override("margin_left", 4)
				margin_c.add_theme_constant_override("margin_top", 4)
				margin_c.add_theme_constant_override("margin_right", 4)
				margin_c.add_theme_constant_override("margin_bottom", 4)
				var hbox := margin_c.get_node_or_null("HBoxContainer") as HBoxContainer
				if hbox:
					hbox.add_theme_constant_override("separation", 12)
			var nick: Label = (card as PlayerCard).get_node_or_null("%NicknameLabel") as Label
			if nick:
				nick.add_theme_font_size_override("font_size", 13)
				nick.add_theme_constant_override("outline_size", 2)


func _wrap_words_container() -> void:
	var parent := words_container.get_parent()
	if not parent:
		return
	
	var wrapper := PanelContainer.new()
	wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.custom_minimum_size = Vector2(0, 72)
	wrapper.clip_contents = true
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 7
	style.content_margin_top = 12
	style.content_margin_right = 7
	style.content_margin_bottom = 12
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.45, 0.45, 0.45, 1)
	wrapper.add_theme_stylebox_override("panel", style)
	
	var idx: int = parent.get_children().find(words_container)
	parent.remove_child(words_container)
	parent.add_child(wrapper)
	parent.move_child(wrapper, idx)
	words_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wrapper.add_child(words_container)


func _wrap_board_grid() -> void:
	var parent := board_grid.get_parent()
	if not parent:
		return
	
	var wrapper := PanelContainer.new()
	wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_WHITE
	style.border_color = Color.BLACK
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	wrapper.add_theme_stylebox_override("panel", style)
	
	var idx: int = parent.get_children().find(board_grid)
	parent.remove_child(board_grid)
	parent.add_child(wrapper)
	parent.move_child(wrapper, idx)
	wrapper.add_child(board_grid)

	_board_wrapper = wrapper


func setup(view_model: GameViewModel, game_id: String, opponent_id: String, me_nickname: String, opponent_nickname: String) -> void:
	_view_model = view_model
	_my_nickname = me_nickname
	_opponent_nickname = opponent_nickname
	_build_board_buttons()
	_connect_view_model()
	_view_model.start(game_id, opponent_id)



func _connect_view_model() -> void:
	_view_model.board_changed.connect(_on_board_changed)
	_view_model.words_changed.connect(_on_words_changed)
	_view_model.my_inventory_changed.connect(_on_my_inventory_changed)
	_view_model.opponent_inventory_changed.connect(_on_opponent_inventory_changed)
	_view_model.power_granted.connect(_on_power_granted)
	_view_model.turn_state_changed.connect(_on_turn_state_changed)
	_view_model.turn_timer_updated.connect(_on_turn_timer_updated)
	_view_model.action_lock_changed.connect(_on_action_lock_changed)
	_view_model.error_changed.connect(_on_error_changed)
	_view_model.effect_state_changed.connect(_on_effect_state_changed)
	_view_model.game_ended.connect(_on_game_ended)
	_view_model.armed_power_changed.connect(_on_armed_power_changed)
	_view_model.notification_requested.connect(_on_notification_requested)
	_view_model.word_found_feedback.connect(_on_word_found_feedback)
	_view_model.trap_event_feedback.connect(_on_trap_event_feedback)
	_view_model.trap_animation_requested.connect(_on_trap_animation_requested)
	_view_model.selected_power_changed.connect(_on_selected_power_changed)



func _build_board_buttons() -> void:
	board_grid.columns = BOARD_SIZE
	board_grid.add_theme_constant_override("h_separation", 1)
	board_grid.add_theme_constant_override("v_separation", 1)
	board_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var button := Button.new()
			button.custom_minimum_size = CELL_SIZE
			button.add_theme_font_size_override("font_size", 12)
			button.pressed.connect(_on_cell_pressed.bind(x, y))
			board_grid.add_child(button)
			_cell_buttons[Vector2i(x, y)] = button


	for cell_position in _cell_buttons:
		_apply_cell_style(cell_position)


var _shake_tween: Tween

func _on_cell_pressed(x: int, y: int) -> void:
	var pos := Vector2i(x, y)
	var state := _view_model.get_cell_visual_state(x, y)
	var is_hidden := state == GameViewModel.CELL_STATE_HIDDEN or state == GameViewModel.CELL_STATE_SPY_ME or state == GameViewModel.CELL_STATE_BLINDED or state == GameViewModel.CELL_STATE_TRAP_ME or state == GameViewModel.CELL_STATE_TRAP_OPPONENT or state == GameViewModel.CELL_STATE_BLOCK_ME or state == GameViewModel.CELL_STATE_BLOCK_OPPONENT
	if not is_hidden:
		return
	if not _view_model.is_my_turn():
		_shake_cell(pos)
		return
	if _view_model.is_frozen():
		_shake_cell(pos)
		return
	_view_model.on_cell_clicked(x, y)


func _shake_cell(cell_position: Vector2i) -> void:
	var bv = _cell_buttons.get(cell_position)
	if not bv is Button:
		return
	var button: Button = bv
	if is_instance_valid(_shake_tween) and _shake_tween.is_valid():
		_shake_tween.kill()
	button.pivot_offset = CELL_SIZE / 2.0
	button.modulate = Color(1, 0.35, 0.35, 1)
	button.scale = Vector2.ONE
	_shake_tween = create_tween()
	_shake_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_shake_tween.tween_property(button, "scale", Vector2(1.06, 1.06), 0.06)
	_shake_tween.tween_property(button, "scale", Vector2(0.97, 0.97), 0.06)
	_shake_tween.tween_property(button, "scale", Vector2(1.04, 1.04), 0.06)
	_shake_tween.tween_property(button, "scale", Vector2.ONE, 0.07)
	_shake_tween.parallel().tween_property(button, "modulate", COLOR_WHITE, 0.25)


func _on_board_changed(_board: GameBoard) -> void:
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var pos := Vector2i(x, y)
			var new_state := _view_model.get_cell_visual_state(x, y)
			var prev_state: Variant = _last_cell_state.get(pos)
			if str(prev_state) != str(new_state):
				var was_hidden: bool = prev_state == null or str(prev_state) == GameViewModel.CELL_STATE_HIDDEN
				var is_revealed: bool = new_state == GameViewModel.CELL_STATE_REVEALED_ME or new_state == GameViewModel.CELL_STATE_REVEALED_OPPONENT or new_state == GameViewModel.CELL_STATE_CLAIMED_ME or new_state == GameViewModel.CELL_STATE_CLAIMED_OPPONENT
				if was_hidden and is_revealed:
					_animate_cell_reveal(pos)
				else:
					_apply_cell_style(pos)
				_last_cell_state[pos] = new_state

	_update_board_interactivity()


func _apply_cell_style(cell_position: Vector2i) -> void:
	var button_variant = _cell_buttons.get(cell_position)

	if not button_variant is Button:
		return

	var button: Button = button_variant
	var state := _view_model.get_cell_visual_state(cell_position.x, cell_position.y)

	button.text = _view_model.get_cell_letter(cell_position.x, cell_position.y)
	_clear_cell_effect_layers(button)

	match state:
		GameViewModel.CELL_STATE_REVEALED_ME:
			_style_cell(button, COLOR_WHITE, COLOR_BLUE, COLOR_TEXT_DARK)
		GameViewModel.CELL_STATE_REVEALED_OPPONENT:
			_style_cell(button, COLOR_WHITE, COLOR_ORANGE, COLOR_TEXT_DARK)
		GameViewModel.CELL_STATE_CLAIMED_ME:
			_style_cell(button, COLOR_BLUE, COLOR_BLUE, COLOR_WHITE)
		GameViewModel.CELL_STATE_CLAIMED_OPPONENT:
			_style_cell(button, COLOR_ORANGE, COLOR_ORANGE, COLOR_WHITE)
		GameViewModel.CELL_STATE_SPY_ME:
			_style_cell(button, COLOR_WHITE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, COLOR_SPY_BORDER)
		GameViewModel.CELL_STATE_BLINDED:
			_style_cell(button, COLOR_BLIND_BG, Color(0, 0, 0, 0), COLOR_BLIND_BG, COLOR_BLIND_BORDER)
		GameViewModel.CELL_STATE_TRAP_ME:
			_style_cell(button, COLOR_WHITE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, COLOR_BLUE)
			_update_cell_trap_icon(button, true)
		GameViewModel.CELL_STATE_TRAP_OPPONENT:
			_style_cell(button, COLOR_WHITE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, COLOR_ORANGE)
			_update_cell_trap_icon(button, true)
		GameViewModel.CELL_STATE_BLOCK_ME:
			_style_cell(button, COLOR_WHITE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, COLOR_BLUE)
			_update_cell_block_bar(button, cell_position, COLOR_BLUE)
		GameViewModel.CELL_STATE_BLOCK_OPPONENT:
			_style_cell(button, COLOR_WHITE, Color(0, 0, 0, 0), COLOR_TEXT_DARK, COLOR_ORANGE)
			_update_cell_block_bar(button, cell_position, COLOR_ORANGE)
		_:
			_style_cell(button, COLOR_WHITE, Color(0, 0, 0, 0), COLOR_TEXT_DARK)


func _animate_cell_reveal(cell_position: Vector2i) -> void:
	var bv = _cell_buttons.get(cell_position)
	if not bv is Button:
		return
	var button: Button = bv
	button.pivot_offset = CELL_SIZE / 2.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(button, "scale", Vector2(0.0, 1.0), 0.10)
	tween.tween_callback(_apply_cell_style.bind(cell_position))
	tween.tween_property(button, "scale", Vector2.ONE, 0.10)


func _style_cell(button: Button, background: Color, state_shadow_color: Color, font: Color, border_color: Color = Color(0, 0, 0, 1)) -> void:
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

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_hover_color", font)
	button.add_theme_color_override("font_pressed_color", font)
	button.add_theme_color_override("font_disabled_color", font)
	button.add_theme_color_override("font_focus_color", font)



var _last_words_signature: String = ""

func _on_words_changed(words: Array) -> void:
	var sig := _words_signature(words)
	if sig == _last_words_signature:
		return
	_last_words_signature = sig
	_rebuild_words(words)


func _words_signature(words: Array) -> String:
	var parts: Array = []
	for w in words:
		if w is GameWord:
			var gw: GameWord = w
			parts.append("%s|%s|%s" % [gw.word, str(gw.found), gw.found_by_player_id])
		else:
			parts.append(str(w))
	return "|".join(parts)


func _rebuild_words(words: Array) -> void:
	for child in words_container.get_children():
		child.queue_free()

	for word_variant in words:
		if not word_variant is GameWord:
			continue

		var word: GameWord = word_variant
		var pill := PanelContainer.new()
		var pill_style := StyleBoxFlat.new()
		pill_style.set_corner_radius_all(10)
		pill_style.content_margin_left = 8
		pill_style.content_margin_top = 2
		pill_style.content_margin_right = 8
		pill_style.content_margin_bottom = 2
		match _view_model.classify_word_owner(word) if _view_model != null else "":
			"me":
				pill_style.bg_color = COLOR_BLUE
			"opponent":
				pill_style.bg_color = COLOR_ORANGE
			_:
				pill_style.bg_color = Color(0.2, 0.2, 0.2, 1)
		pill.add_theme_stylebox_override("panel", pill_style)

		var label := Label.new()
		label.text = word.word.to_upper()
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pill.add_child(label)
		words_container.add_child(pill)



func _on_my_inventory_changed(inventory: Array) -> void:
	var present: Array = []

	for item in inventory:
		if not (item is GamePower):
			continue

		var power: GamePower = item

		if not _power_seen_seq.has(power.id):
			_power_seq_counter += 1
			_power_seen_seq[power.id] = _power_seq_counter

		present.append(power)

	present.sort_custom(func(a: GamePower, b: GamePower) -> bool: return int(_power_seen_seq[a.id]) < int(_power_seen_seq[b.id]))

	var present_ids := {}

	for power in present:
		present_ids[(power as GamePower).id] = true

	for seen_id in _power_seen_seq.keys():
		if not present_ids.has(seen_id):
			_power_seen_seq.erase(seen_id)

	_cached_my_inventory = present
	_update_inventory_panel()


func _on_opponent_inventory_changed(inventory: Array) -> void:
	_cached_opponent_inventory = inventory
	_update_opponent_power_dots()



const DASHED_SLOT_FRAME_SCRIPT := preload("res://features/game/presentation/views/dashed_slot_frame.gd")


func _update_inventory_panel() -> void:
	for index in GamePlayerState.INVENTORY_SIZE:
		if index >= _inventory_slots.size():
			continue

		var slot_variant = _inventory_slots[index]

		if not slot_variant is TextureButton:
			continue

		var slot: TextureButton = slot_variant
		var frame := slot.get_parent() as PanelContainer
		var power = _cached_my_inventory[index] if index < _cached_my_inventory.size() else null

		if power is GamePower:
			slot.texture_normal = _power_icon(power.type)
			var solid_style := StyleBoxFlat.new()
			solid_style.bg_color = Color(0, 0, 0, 0)
			solid_style.corner_radius_top_left = 8
			solid_style.corner_radius_top_right = 8
			solid_style.corner_radius_bottom_right = 8
			solid_style.corner_radius_bottom_left = 8
			solid_style.border_width_left = 0
			solid_style.border_width_top = 0
			solid_style.border_width_right = 0
			solid_style.border_width_bottom = 0
			solid_style.content_margin_left = 0
			solid_style.content_margin_top = 0
			solid_style.content_margin_right = 0
			solid_style.content_margin_bottom = 0
			frame.add_theme_stylebox_override("panel", solid_style)
			frame.clip_contents = false
			if frame.get_script():
				frame.set_script(null)

			slot.texture_normal = _power_icon(power.type)
			slot.material = _rounded_icon_material()

			var icon_style := StyleBoxFlat.new()
			icon_style.bg_color = Color(0, 0, 0, 0)
			icon_style.corner_radius_top_left = 8
			icon_style.corner_radius_top_right = 8
			icon_style.corner_radius_bottom_right = 8
			icon_style.corner_radius_bottom_left = 8
			slot.add_theme_stylebox_override("normal", icon_style)
			slot.add_theme_stylebox_override("hover", icon_style)
			slot.add_theme_stylebox_override("pressed", icon_style)
			slot.add_theme_stylebox_override("disabled", icon_style)
			slot.add_theme_stylebox_override("focus", icon_style)
		else:
			slot.texture_normal = null
			slot.material = null
			frame.clip_contents = false
			if frame.get_script() != DASHED_SLOT_FRAME_SCRIPT:
				frame.set_script(DASHED_SLOT_FRAME_SCRIPT)
			var empty_style := StyleBoxFlat.new()
			empty_style.bg_color = Color(0, 0, 0, 0)
			frame.add_theme_stylebox_override("panel", empty_style)

			var empty_icon_style := StyleBoxFlat.new()
			empty_icon_style.bg_color = Color(0, 0, 0, 0)
			slot.add_theme_stylebox_override("normal", empty_icon_style)
			slot.add_theme_stylebox_override("hover", empty_icon_style)
			slot.add_theme_stylebox_override("pressed", empty_icon_style)

	_update_armed_power_highlight()

	_update_power_dots(_my_dots, _cached_my_inventory)


const ARMED_LIFT_Y := -10.0
const ARMED_LIFT_SCALE := Vector2(1.12, 1.12)
const ARMED_LIFT_DURATION := 0.18
const ARMED_SNAP_DURATION := 0.14
const ARMED_SHADOW_SIZE := 6

func _update_armed_power_highlight() -> void:
	var armed_id := _view_model.selected_power_id()
	for index in _inventory_slots.size():
		var slot_variant = _inventory_slots[index]
		if not slot_variant is TextureButton:
			continue
		var slot: TextureButton = slot_variant
		var frame := slot.get_parent() as PanelContainer
		var power = _cached_my_inventory[index] if index < _cached_my_inventory.size() else null
		var is_armed: bool = power is GamePower and power.id == armed_id
		_animate_slot_lift(slot, frame, is_armed)


func _ensure_global_arrow(frame: PanelContainer, show: bool) -> void:
	if not is_instance_valid(frame):
		return
	var arrow: Control = frame.get_node_or_null("GlobalArrow") as Control
	if show:
		if arrow == null:
			arrow = Label.new()
			arrow.name = "GlobalArrow"
			arrow.text = "▲"
			(arrow as Label).add_theme_font_size_override("font_size", 18)
			(arrow as Label).add_theme_color_override("font_color", Color(0.18, 0.80, 0.44, 1))
			arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			arrow.position = Vector2(14, -30)
			arrow.size = Vector2(24, 18)
			arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			arrow.z_index = 15
			frame.add_child(arrow)
			var bounce := create_tween()
			bounce.set_loops()
			bounce.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			bounce.tween_property(arrow, "position:y", -38.0, 0.30)
			bounce.tween_property(arrow, "position:y", -30.0, 0.30)
			arrow.set_meta("bounce", bounce)
		arrow.visible = true
	else:
		if arrow != null:
			if arrow.has_meta("bounce"):
				var b = arrow.get_meta("bounce")
				if b is Tween and b.is_valid():
					b.kill()
			arrow.queue_free()


func _animate_slot_lift(slot: TextureButton, frame: PanelContainer, lifted: bool) -> void:
	if not is_instance_valid(slot):
		return
	slot.pivot_offset = Vector2(26, 26)
	if slot.size == Vector2.ZERO:
		slot.pivot_offset = Vector2(26, 26)
	var meta_key := "lift_tween"
	if slot.has_meta(meta_key):
		var old = slot.get_meta(meta_key)
		if old is Tween and old.is_valid():
			old.kill()
	if is_instance_valid(frame):
		frame.clip_contents = false
		var fstyle := frame.get_theme_stylebox("panel") as StyleBoxFlat
		if fstyle != null:
			if lifted:
				fstyle.border_width_left = 2
				fstyle.border_width_top = 2
				fstyle.border_width_right = 2
				fstyle.border_width_bottom = 2
				fstyle.border_color = Color.WHITE
				fstyle.bg_color = Color(0, 0, 0, 0)
				fstyle.shadow_color = Color(0.047, 1, 0.396, 0.9)
			else:
				fstyle.border_width_left = 0
				fstyle.border_width_top = 0
				fstyle.border_width_right = 0
				fstyle.border_width_bottom = 0
				fstyle.border_color = Color(0, 0, 0, 0)
				fstyle.bg_color = Color(0, 0, 0, 0)
				fstyle.shadow_color = Color(0, 0, 0, 0)
				fstyle.shadow_size = 0
	var tween := create_tween()
	slot.set_meta(meta_key, tween)
	tween.set_trans(Tween.TRANS_BACK if lifted else Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if lifted:
		tween.tween_property(slot, "position:y", ARMED_LIFT_Y, ARMED_LIFT_DURATION)
		tween.parallel().tween_property(slot, "scale", ARMED_LIFT_SCALE, 0.16)
		tween.parallel().tween_property(slot, "modulate", Color.WHITE, 0.16)
		if is_instance_valid(frame):
			var fs := frame.get_theme_stylebox("panel") as StyleBoxFlat
			if fs != null:
				tween.parallel().tween_property(fs, "shadow_size", 4, ARMED_LIFT_DURATION)
		slot.z_index = 10
		if _armed_scope == GamePowerCatalog.SCOPE_GLOBAL:
			_ensure_global_arrow(frame, true)
		else:
			_ensure_global_arrow(frame, false)
	else:
		tween.tween_property(slot, "position:y", 0.0, ARMED_SNAP_DURATION)
		tween.parallel().tween_property(slot, "scale", Vector2.ONE, ARMED_SNAP_DURATION)
		tween.parallel().tween_property(slot, "modulate", Color.WHITE, ARMED_SNAP_DURATION)
		slot.z_index = 0
		_ensure_global_arrow(frame, false)
	tween.finished.connect(func() -> void:
		if slot.has_meta(meta_key) and slot.get_meta(meta_key) == tween:
			slot.remove_meta(meta_key)
	)


func _on_power_slot_pressed(slot_index: int) -> void:
	if slot_index >= _cached_my_inventory.size():
		return
	var power = _cached_my_inventory[slot_index]
	if not (power is GamePower):
		return
	_view_model.on_power_clicked(power.id)


func _on_power_granted(power: GamePower) -> void:
	var slot := _find_inventory_slot_by_power_id(power.id)

	if slot == null:
		return

	if is_instance_valid(_power_grant_tween) and _power_grant_tween.is_valid():
		_power_grant_tween.kill()

	slot.pivot_offset = slot.size / 2.0

	_power_grant_tween = create_tween()
	_power_grant_tween.tween_property(slot, "scale", Vector2(1.25, 1.25), POWER_GRANT_PULSE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_power_grant_tween.parallel().tween_property(slot, "modulate", POWER_GRANT_FLASH_COLOR, POWER_GRANT_PULSE_DURATION)
	_power_grant_tween.tween_property(slot, "scale", Vector2.ONE, POWER_GRANT_SETTLE_DURATION)
	_power_grant_tween.parallel().tween_property(slot, "modulate", COLOR_WHITE, POWER_GRANT_SETTLE_DURATION)


func _find_inventory_slot_by_power_id(power_id: String) -> TextureButton:
	for index in _cached_my_inventory.size():
		var power = _cached_my_inventory[index]

		if power is GamePower and power.id == power_id and index < _inventory_slots.size():
			return _inventory_slots[index]

	return null


func _on_inventory_icon_gui_input(event: InputEvent, slot_index: int) -> void:
	if slot_index >= _cached_my_inventory.size():
		return

	var power = _cached_my_inventory[slot_index]
	if not (power is GamePower):
		return

	if power.id != _view_model.selected_power_id():
		return

	var slot: TextureButton = _inventory_slots[slot_index] if slot_index < _inventory_slots.size() else null
	if slot == null:
		return

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_drag_start_y = event.position.y
			_dragging_slot_index = slot_index
			if slot.has_meta("lift_tween"):
				var lt = slot.get_meta("lift_tween")
				if lt is Tween and lt.is_valid():
					lt.kill()
					slot.remove_meta("lift_tween")
			slot.z_index = 10
		else:
			if _dragging_slot_index == slot_index:
				var delta_end: float = event.position.y - _drag_start_y
				if abs(delta_end) < GLOBAL_SWIPE_THRESHOLD_PX:
					_snap_back_slot(slot)
			_dragging_slot_index = -1
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _dragging_slot_index != slot_index:
			return
		var delta: float = event.position.y - _drag_start_y
		var clamped: float = clamp(delta, -60.0, 60.0)
		slot.position.y = ARMED_LIFT_Y + clamped
		var frame := slot.get_parent() as PanelContainer
		if delta < -20.0:
			if _armed_scope == GamePowerCatalog.SCOPE_GLOBAL:
				_apply_drag_preview(slot, frame, true, false)
			else:
				_apply_drag_preview(slot, frame, false, false)
		elif delta > 20.0:
			_apply_drag_preview(slot, frame, false, true)
		else:
			_apply_drag_preview(slot, frame, false, false)
			slot.position.y = ARMED_LIFT_Y + clamped
			slot.scale = ARMED_LIFT_SCALE if abs(clamped) < 5 else Vector2(0.95, 0.95)
		if delta < -GLOBAL_SWIPE_THRESHOLD_PX:
			if _armed_scope != GamePowerCatalog.SCOPE_GLOBAL:
				_snap_back_slot(slot)
				_dragging_slot_index = -1
				return
			_dragging_slot_index = -1
			_animate_launch_slot(slot)
			await (Engine.get_main_loop() as SceneTree).create_timer(0.3).timeout
			_view_model.confirm_armed_global_power()
		elif delta > GLOBAL_SWIPE_THRESHOLD_PX:
			_dragging_slot_index = -1
			_animate_discard_slot(slot)
			await (Engine.get_main_loop() as SceneTree).create_timer(0.3).timeout
			_view_model.discard_armed_power()


func _apply_drag_preview(slot: TextureButton, frame: PanelContainer, is_using: bool, is_discarding: bool) -> void:
	if not is_instance_valid(slot):
		return
	slot.pivot_offset = Vector2(26, 26)
	if is_using:
		slot.scale = Vector2(0.95, 0.95)
		slot.modulate = Color(1, 1, 1, 1)
		if is_instance_valid(frame):
			var fs := frame.get_theme_stylebox("panel") as StyleBoxFlat
			if fs != null:
				fs.border_width_left = 2
				fs.border_width_top = 2
				fs.border_width_right = 2
				fs.border_width_bottom = 2
				fs.border_color = Color(0.18, 0.80, 0.44, 1) # #2ecc71
				fs.bg_color = Color(0, 0, 0, 0)
				fs.shadow_color = Color(0.18, 0.80, 0.44, 0.8)
				fs.shadow_size = 25
	elif is_discarding:
		slot.scale = Vector2(0.95, 0.95)
		slot.modulate = Color(0.6, 0.6, 0.6, 1)
		if is_instance_valid(frame):
			var fs := frame.get_theme_stylebox("panel") as StyleBoxFlat
			if fs != null:
				fs.border_width_left = 2
				fs.border_width_top = 2
				fs.border_width_right = 2
				fs.border_width_bottom = 2
				fs.border_color = Color(1, 0.28, 0.34, 1) # #ff4757
				fs.bg_color = Color(0, 0, 0, 0)
				fs.shadow_color = Color(1, 0.28, 0.34, 0.8)
				fs.shadow_size = 20
	else:
		slot.scale = ARMED_LIFT_SCALE
		slot.modulate = Color.WHITE
		if is_instance_valid(frame):
			var fs := frame.get_theme_stylebox("panel") as StyleBoxFlat
			if fs != null:
				fs.border_width_left = 2
				fs.border_width_top = 2
				fs.border_width_right = 2
				fs.border_width_bottom = 2
				fs.border_color = Color.WHITE
				fs.bg_color = Color(0, 0, 0, 0)
				fs.shadow_color = Color(0.047, 1, 0.396, 0.9)
				fs.shadow_size = 4


func _snap_back_slot(slot: TextureButton) -> void:
	if not is_instance_valid(slot):
		return
	if slot.has_meta("drag_tween"):
		var dt = slot.get_meta("drag_tween")
		if dt is Tween and dt.is_valid():
			dt.kill()
	var frame := slot.get_parent() as PanelContainer
	slot.pivot_offset = Vector2(26, 26)
	var tween := create_tween()
	slot.set_meta("drag_tween", tween)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(slot, "position:y", ARMED_LIFT_Y, 0.22)
	tween.parallel().tween_property(slot, "scale", ARMED_LIFT_SCALE, 0.22)
	tween.parallel().tween_property(slot, "modulate", Color.WHITE, 0.16)
	if is_instance_valid(frame):
		var fs := frame.get_theme_stylebox("panel") as StyleBoxFlat
		if fs != null:
			tween.parallel().tween_property(fs, "border_color", Color.WHITE, 0.16)
			tween.parallel().tween_property(fs, "shadow_size", 4, 0.22)
	tween.finished.connect(func() -> void:
		if slot.has_meta("drag_tween") and slot.get_meta("drag_tween") == tween:
			slot.remove_meta("drag_tween")
	)


func _animate_launch_slot(slot: TextureButton) -> void:
	if not is_instance_valid(slot):
		return
	slot.pivot_offset = Vector2(26, 26)
	if slot.has_meta("lift_tween"):
		var lt = slot.get_meta("lift_tween")
		if lt is Tween and lt.is_valid():
			lt.kill()
			slot.remove_meta("lift_tween")
	var tween := create_tween()
	slot.set_meta("exit_tween", tween)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(slot, "scale", Vector2(1.18, 1.18), 0.15)
	tween.parallel().tween_property(slot, "modulate", Color(2, 2, 2, 1), 0.15)
	tween.tween_property(slot, "scale", Vector2(1.5, 1.5), 0.35)
	tween.parallel().tween_property(slot, "position:y", -120.0, 0.35)
	tween.parallel().tween_property(slot, "rotation", deg_to_rad(8), 0.35)
	tween.parallel().tween_property(slot, "modulate:a", 0.0, 0.35)
	slot.z_index = 50
	tween.finished.connect(func() -> void:
		if slot.has_meta("exit_tween") and slot.get_meta("exit_tween") == tween:
			slot.remove_meta("exit_tween")
		slot.position.y = 0
		slot.scale = Vector2.ONE
		slot.rotation = 0
		slot.modulate = Color.WHITE
		slot.z_index = 0
	)


func _animate_discard_slot(slot: TextureButton) -> void:
	if not is_instance_valid(slot):
		return
	slot.pivot_offset = Vector2(26, 26)
	if slot.has_meta("lift_tween"):
		var lt = slot.get_meta("lift_tween")
		if lt is Tween and lt.is_valid():
			lt.kill()
			slot.remove_meta("lift_tween")
	var tween := create_tween()
	slot.set_meta("exit_tween", tween)
	slot.z_index = 30
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(slot, "scale", Vector2(1.08, 1.08), 0.17)
	tween.parallel().tween_property(slot, "rotation", deg_to_rad(-6), 0.17)
	tween.tween_property(slot, "scale", Vector2(0.3, 0.3), 0.25)
	tween.parallel().tween_property(slot, "position:y", 80.0, 0.25)
	tween.parallel().tween_property(slot, "rotation", deg_to_rad(20), 0.25)
	tween.parallel().tween_property(slot, "modulate:a", 0.0, 0.25)
	tween.finished.connect(func() -> void:
		if slot.has_meta("exit_tween") and slot.get_meta("exit_tween") == tween:
			slot.remove_meta("exit_tween")
		slot.position.y = 0
		slot.scale = Vector2.ONE
		slot.rotation = 0
		slot.modulate = Color.WHITE
		slot.z_index = 0
	)


func _on_armed_power_changed(_power_id: String, _power_type: String, scope: String) -> void:
	_armed_scope = scope
	_update_armed_power_highlight()

	if scope == GamePowerCatalog.SCOPE_CELL:
		_global_power_armed = false
		_update_board_interactivity()
		_start_board_pulse()
	elif scope == GamePowerCatalog.SCOPE_GLOBAL:
		_global_power_armed = true
		_stop_board_pulse()
		_update_board_interactivity()
	else:
		_global_power_armed = false
		_stop_board_pulse()
		_update_board_interactivity()


func _start_board_pulse() -> void:
	if _board_wrapper == null:
		return

	var style := _board_wrapper.get_theme_stylebox("panel") as StyleBoxFlat

	if style == null:
		return

	if is_instance_valid(_pulse_tween) and _pulse_tween.is_valid():
		_pulse_tween.kill()

	style.shadow_color = COLOR_NEON_GREEN
	style.shadow_size = 0

	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(style, "shadow_size", BOARD_PULSE_MAX_SHADOW, BOARD_PULSE_DURATION)
	_pulse_tween.tween_property(style, "shadow_size", 0, BOARD_PULSE_DURATION)


func _stop_board_pulse() -> void:
	if is_instance_valid(_pulse_tween) and _pulse_tween.is_valid():
		_pulse_tween.kill()

	if _board_wrapper != null:
		var style := _board_wrapper.get_theme_stylebox("panel") as StyleBoxFlat

		if style != null:
			style.shadow_size = 0


func _update_opponent_power_dots() -> void:
	_update_power_dots(_opponent_dots, _cached_opponent_inventory)


func _count_occupied(inventory: Array) -> int:
	var occupied := 0

	for power in inventory:
		if power is GamePower:
			occupied += 1

	return occupied


var _dot_pulse_tween: Tween

const DOT_FILLED_BG := Color(1, 1, 1, 0.95)
const DOT_EMPTY_BG := Color(0.5, 0.5, 0.5, 0.6)

func _update_power_dots(dots: Array, inventory: Array) -> void:
	var occupied := _count_occupied(inventory)

	for index in dots.size():
		var dot_variant = dots[index]

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
	tween.finished.connect(func() -> void:
		if dot.has_meta("dot_tween") and dot.get_meta("dot_tween") == tween:
			dot.remove_meta("dot_tween")
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
	tween.finished.connect(func() -> void:
		if dot.has_meta("dot_tween") and dot.get_meta("dot_tween") == tween:
			dot.remove_meta("dot_tween")
	)


func _power_icon(power_type: String) -> Texture2D:
	if _icon_cache.has(power_type):
		return _icon_cache[power_type]

	var path = PlayerCard.POWER_ICON_PATHS.get(power_type)

	if path == null:
		return null

	var texture := load(str(path)) as Texture2D
	_icon_cache[power_type] = texture

	return texture


func _rounded_icon_material() -> ShaderMaterial:
	var cached = _icon_cache.get("__rounded_mat")

	if cached is ShaderMaterial:
		return cached

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform float radius = 12.0;
void fragment() {
	vec2 size = vec2(52.0, 52.0);
	vec2 uv = UV;
	vec2 pos = uv * size;
	float r = radius;
	if (pos.x < r && pos.y < r) {
		if (distance(pos, vec2(r, r)) > r) discard;
	} else if (pos.x > size.x - r && pos.y < r) {
		if (distance(pos, vec2(size.x - r, r)) > r) discard;
	} else if (pos.x < r && pos.y > size.y - r) {
		if (distance(pos, vec2(r, size.y - r)) > r) discard;
	} else if (pos.x > size.x - r && pos.y > size.y - r) {
		if (distance(pos, vec2(size.x - r, size.y - r)) > r) discard;
	}
	COLOR = texture(TEXTURE, uv);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("radius", 8.0)
	_icon_cache["__rounded_mat"] = mat

	return mat



func _on_turn_state_changed(is_my_turn: bool) -> void:
	_cached_is_my_turn = is_my_turn
	_update_player_cards()
	_update_turn_label()
	_update_inventory_panel()


func _update_player_cards() -> void:
	var appearing_wrapper: Control = my_card_wrapper if _cached_is_my_turn else opponent_card_wrapper

	if _cached_is_my_turn:
		my_player_card.show_local(_my_nickname)
		my_power_dots.show()
		opponent_player_card.clear()
		opponent_power_dots.hide()
	else:
		opponent_player_card.show_opponent(_opponent_nickname)
		opponent_power_dots.show()
		my_player_card.clear()
		my_power_dots.hide()

	if is_instance_valid(_cards_fade_tween) and _cards_fade_tween.is_valid():
		_cards_fade_tween.kill()
	appearing_wrapper.modulate.a = 0.0
	_cards_fade_tween = create_tween()
	_cards_fade_tween.tween_property(appearing_wrapper, "modulate:a", 1.0, CARD_FADE_DURATION)


func _on_turn_timer_updated(seconds_remaining: float) -> void:
	_cached_seconds_remaining = seconds_remaining
	_update_turn_label()


func _update_turn_label() -> void:
	var seconds := int(_cached_seconds_remaining)

	if _cached_is_my_turn:
		turn_label.text = "Sua vez — %ds" % seconds
	else:
		turn_label.text = "Vez do oponente — %ds" % seconds



func _on_effect_state_changed() -> void:
	_update_board_interactivity()
	_refresh_all_cell_styles()

	if _view_model == null:
		return

	var blinded_now := _view_model.is_blinded()
	var frozen_now := _view_model.is_frozen()
	var immune_now := _view_model.is_immune()

	if frozen_now:
		_hide_blind_vignette()
		_show_effect_overlay(EFFECT_FREEZE_COLOR)
	elif immune_now:
		_hide_blind_vignette()
		_show_effect_overlay(EFFECT_IMMUNITY_COLOR)
	elif blinded_now:
		_hide_effect_overlay()
		_show_blind_vignette()
	else:
		_hide_effect_overlay()
		_hide_blind_vignette()
		if _was_blinded:
			_flash_effect_overlay(EFFECT_LANTERN_FLASH, 0.5)
		elif _was_frozen:
			_flash_effect_overlay(EFFECT_UNFREEZE_HOT, UNFREEZE_HOT_HOLD)

	_was_blinded = blinded_now
	_was_frozen = frozen_now


func _refresh_all_cell_styles() -> void:
	if _view_model == null or _cell_buttons.is_empty():
		return

	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var pos := Vector2i(x, y)
			var new_state := _view_model.get_cell_visual_state(x, y)

			if _last_cell_state.get(pos) != new_state:
				_apply_cell_style(pos)
				_last_cell_state[pos] = new_state


func _ensure_effect_overlay() -> void:
	if is_instance_valid(_effect_overlay):
		return

	_effect_overlay = ColorRect.new()
	_effect_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_effect_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_effect_overlay.z_index = 50
	_effect_overlay.modulate.a = 0.0
	_effect_overlay.visible = false
	add_child(_effect_overlay)


func _show_effect_overlay(color: Color) -> void:
	_ensure_effect_overlay()

	if is_instance_valid(_flash_tween) and _flash_tween.is_valid():
		_flash_tween.kill()

	_effect_overlay.color = color
	_effect_overlay.visible = true

	if is_instance_valid(_effect_tween) and _effect_tween.is_valid():
		_effect_tween.kill()

	_effect_tween = create_tween()
	_effect_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_effect_tween.tween_property(_effect_overlay, "modulate:a", 1.0, EFFECT_OVERLAY_FADE)


func _hide_effect_overlay() -> void:
	if not is_instance_valid(_effect_overlay):
		return

	if is_instance_valid(_flash_tween) and _flash_tween.is_valid():
		_flash_tween.kill()

	if is_instance_valid(_effect_tween) and _effect_tween.is_valid():
		_effect_tween.kill()

	_effect_tween = create_tween()
	_effect_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_effect_tween.tween_property(_effect_overlay, "modulate:a", 0.0, EFFECT_OVERLAY_FADE)
	_effect_tween.tween_callback(_effect_overlay.hide)


func _flash_effect_overlay(color: Color, hold_seconds: float) -> void:
	_ensure_effect_overlay()

	if is_instance_valid(_effect_tween) and _effect_tween.is_valid():
		_effect_tween.kill()

	if is_instance_valid(_flash_tween) and _flash_tween.is_valid():
		_flash_tween.kill()

	_effect_overlay.color = color
	_effect_overlay.visible = true
	_effect_overlay.modulate.a = 0.0

	_flash_tween = create_tween()
	_flash_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_property(_effect_overlay, "modulate:a", 1.0, 0.2)
	_flash_tween.tween_interval(hold_seconds)
	_flash_tween.tween_property(_effect_overlay, "modulate:a", 0.0, 0.5)
	_flash_tween.tween_callback(_effect_overlay.hide)


func _ensure_blind_vignette() -> void:
	if is_instance_valid(_blind_vignette):
		return

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 51
	root.modulate.a = 0.0
	root.visible = false

	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0.12))
	gradient.set_color(1, Color(0, 0, 0, 0.9))
	gradient.add_point(0.55, Color(0, 0, 0, 0.32))
	gradient.add_point(0.8, Color(0, 0, 0, 0.62))

	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)

	var vignette := TextureRect.new()
	vignette.texture = texture
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vignette)

	add_child(root)
	_blind_vignette = root


func _show_blind_vignette() -> void:
	_ensure_blind_vignette()
	_blind_vignette.visible = true

	if is_instance_valid(_blind_tween) and _blind_tween.is_valid():
		_blind_tween.kill()

	_blind_tween = create_tween()
	_blind_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_blind_tween.tween_property(_blind_vignette, "modulate:a", 1.0, EFFECT_OVERLAY_FADE)


func _hide_blind_vignette() -> void:
	if not is_instance_valid(_blind_vignette):
		return

	if is_instance_valid(_blind_tween) and _blind_tween.is_valid():
		_blind_tween.kill()

	_blind_tween = create_tween()
	_blind_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_blind_tween.tween_property(_blind_vignette, "modulate:a", 0.0, EFFECT_OVERLAY_FADE)
	_blind_tween.tween_callback(_blind_vignette.hide)


func _trap_cell_texture() -> Texture2D:
	if _icon_cache.has("TRAP_CELL"):
		return _icon_cache["TRAP_CELL"]

	var texture := load(TRAP_CELL_ICON_PATH) as Texture2D
	_icon_cache["TRAP_CELL"] = texture

	return texture


func _update_cell_trap_icon(button: Button, show: bool) -> void:
	var layer := _get_cell_extra(button, "TrapIcon")

	for child in layer.get_children():
		child.queue_free()

	layer.visible = show

	if not show:
		return

	var icon := TextureRect.new()
	icon.texture = _trap_cell_texture()
	icon.custom_minimum_size = TRAP_ICON_SIZE
	icon.size = TRAP_ICON_SIZE
	icon.position = (CELL_SIZE - TRAP_ICON_SIZE) / 2.0
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(icon)


func _update_cell_block_bar(button: Button, cell_position: Vector2i, fill_color: Color) -> void:
	var layer := _get_cell_extra(button, "BlockBar")

	for child in layer.get_children():
		child.queue_free()

	layer.visible = true

	var filled := _view_model.get_cell_block_filled(cell_position.x, cell_position.y)

	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = 4
	bar.offset_right = -4
	bar.offset_top = -6
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 2)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(bar)

	for i in BLOCK_BAR_SEGMENTS:
		var segment := ColorRect.new()
		segment.custom_minimum_size = Vector2(7, 4)
		segment.color = fill_color if i < filled else BLOCK_BAR_EMPTY
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_child(segment)


func _clear_cell_effect_layers(button: Button) -> void:
	for layer_name in ["TrapIcon", "BlockBar"]:
		var layer := button.get_node_or_null(layer_name)

		if layer is Control:
			for child in (layer as Control).get_children():
				child.queue_free()

			(layer as Control).visible = false


func _pop_trap_cell(cell_position: Vector2i) -> void:
	var button_variant = _cell_buttons.get(cell_position)

	if not button_variant is Button:
		return

	var button: Button = button_variant
	_update_cell_trap_icon(button, true)
	button.pivot_offset = CELL_SIZE / 2.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", TRAP_POP_SCALE, 0.1)
	tween.tween_property(button, "scale", Vector2.ONE, 0.1)


func _break_block_cell(cell_position: Vector2i) -> void:
	var button_variant = _cell_buttons.get(cell_position)

	if not button_variant is Button:
		return

	var button: Button = button_variant
	button.pivot_offset = CELL_SIZE / 2.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", UNBLOCK_POP_SCALE, 0.08)
	tween.tween_property(button, "scale", Vector2.ONE, 0.12)


func _restyle_cell(cell_position: Vector2i) -> void:
	if not _cell_buttons.has(cell_position):
		return

	_apply_cell_style(cell_position)
	_last_cell_state[cell_position] = _view_model.get_cell_visual_state(cell_position.x, cell_position.y)


func _get_cell_extra(button: Button, layer_name: String) -> Control:
	var existing := button.get_node_or_null(layer_name)

	if existing is Control:
		return existing

	var layer := Control.new()
	layer.name = layer_name
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(layer)

	return layer


func _on_notification_requested(message: String) -> void:
	if message.is_empty():
		return

	status_label.text = message
	status_label.show()


func _on_word_found_feedback(cells: Array, _is_me: bool) -> void:
	for cell_variant in cells:
		if not cell_variant is Vector2i:
			continue

		var pos: Vector2i = cell_variant

		if not _cell_buttons.has(pos):
			continue

		_last_cell_state.erase(pos)
		_apply_cell_style(pos)
		_last_cell_state[pos] = _view_model.get_cell_visual_state(pos.x, pos.y)

	if _view_model != null and _view_model.board() != null:
		_refresh_all_cell_styles()

	if _view_model != null:
		_last_words_signature = ""
		_on_words_changed(_view_model.words())


func _on_trap_event_feedback(event_name: String, x: int, y: int) -> void:
	match event_name:
		"TRAP_TRIGGERED":
			_pop_trap_cell(Vector2i(x, y))
		"CELL_TRAPPED", "CELL_BLOCKED", "CELL_STILL_BLOCKED", "TRAP_REMOVED", "TRAP_DETECTED":
			_restyle_cell(Vector2i(x, y))
		"CELL_UNBLOCKED":
			_break_block_cell(Vector2i(x, y))
			_restyle_cell(Vector2i(x, y))
		_:
			_shake_cell(Vector2i(x, y))


func _on_trap_animation_requested(x: int, y: int) -> void:
	_shake_cell(Vector2i(x, y))


func _on_selected_power_changed(_power_id: String) -> void:
	_update_armed_power_highlight()



func _on_action_lock_changed(is_locked: bool) -> void:
	_action_locked = is_locked
	_update_board_interactivity()


func _update_board_interactivity() -> void:
	var board_disabled := _global_power_armed or _action_locked
	if _view_model != null and _view_model.is_frozen() and _armed_scope == GamePowerCatalog.SCOPE_GLOBAL:
		var selected_id := _view_model.selected_power_id()
		for p in _cached_my_inventory:
			if p is GamePower and (p as GamePower).id == selected_id and GamePowerCatalog.can_use_while_frozen((p as GamePower).type):
				board_disabled = false
				break

	board_grid.modulate = BOARD_DIMMED_MODULATE if board_disabled else COLOR_WHITE
	board_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE if board_disabled else Control.MOUSE_FILTER_STOP

	for cell_position in _cell_buttons:
		var button_variant = _cell_buttons.get(cell_position)

		if not button_variant is Button:
			continue

		var button: Button = button_variant
		var vs := _view_model.get_cell_visual_state(cell_position.x, cell_position.y)
		var cell_revealed := vs == GameViewModel.CELL_STATE_REVEALED_ME or vs == GameViewModel.CELL_STATE_REVEALED_OPPONENT or vs == GameViewModel.CELL_STATE_CLAIMED_ME or vs == GameViewModel.CELL_STATE_CLAIMED_OPPONENT
		var cell_disabled := board_disabled or cell_revealed

		button.mouse_filter = Control.MOUSE_FILTER_IGNORE if cell_disabled else Control.MOUSE_FILTER_STOP


func _on_error_changed(message: String) -> void:
	if message.is_empty():
		status_label.hide()
		status_label.text = ""
	else:
		status_label.text = message
		status_label.show()



func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(_view_model):
			_view_model.leave_game()
		get_tree().quit()

func _exit_tree() -> void:
	if is_instance_valid(_view_model) and not _navigation_started:
		_view_model.leave_game()


func _on_leave_button_pressed() -> void:
	leave_button.disabled = true
	_view_model.leave_game()
	_navigate_home()


func _on_game_ended(_is_winner: bool, _title: String, _subtitle: String) -> void:
	leave_button.disabled = true
	_show_game_over_overlay(_is_winner, _title, _subtitle)


func _show_game_over_overlay(is_winner: bool, title: String, subtitle: String) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 0)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.1, 1)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.7, 0.7, 0.7, 1)
	panel.add_theme_stylebox_override("panel", panel_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2, 1) if is_winner else Color(1.0, 0.3, 0.3, 1))
	vbox.add_child(title_label)

	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.add_theme_font_size_override("font_size", 16)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	vbox.add_child(subtitle_label)

	var home_button := Button.new()
	home_button.text = "Voltar ao Início"
	home_button.custom_minimum_size = Vector2(200, 50)
	home_button.add_theme_font_size_override("font_size", 18)
	home_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	home_button.pressed.connect(_navigate_home)
	vbox.add_child(home_button)

	margin.add_child(vbox)
	panel.add_child(margin)
	center.add_child(panel)
	overlay.add_child(center)
	add_child(overlay)


func _navigate_home() -> void:
	if _navigation_started:
		return

	_navigation_started = true
	_view_model.go_to_home()
