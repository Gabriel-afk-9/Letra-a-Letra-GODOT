extends Control
class_name GameScreen

const BOARD_SIZE := 10
const COLOR_BLUE := Color(0.101960786, 0.57254905, 0.9019608, 1)
const COLOR_ORANGE := Color(0.9529412, 0.52156866, 0.09411765, 1)

const EFFECT_FREEZE_COLOR := Color(0.2, 0.5, 1.0, 0.25)
const EFFECT_IMMUNITY_COLOR := Color(1.0, 0.55, 0.1, 0.35)
const EFFECT_LANTERN_FLASH := Color(1, 1, 1, 0.6)
const EFFECT_UNFREEZE_HOT := Color(1.0, 0.45, 0.15, 0.4)
const EFFECT_SPY_WASH := Color(0.15, 0.6, 1.0, 0.18)
const EFFECT_DETECT_WASH := Color(1.0, 0.85, 0.2, 0.15)
const EFFECT_IMMUNITY_END_FLASH := Color(1, 1, 1, 0.45)
const UNFREEZE_HOT_HOLD := 2.0
@onready var player_info_bar: PlayerInfoBar = $MarginContainer/MainLayout/PlayerInfoBar
@onready var words_container_view: WordsContainerView = $MarginContainer/MainLayout/WordsContainerView
@onready var board_view: BoardView = $MarginContainer/MainLayout/BoardView
@onready var _main_layout: VBoxContainer = $MarginContainer/MainLayout
@onready var _inventory_panel: InventoryPanel = $MarginContainer/MainLayout/InventoryPanel
@onready var leave_button: Button = $TopBarLeaveButton

var _view_model: GameViewModel
var _cell_buttons: Dictionary = {}
var _last_cell_state: Dictionary = {}
@onready var _effect_overlay: EffectOverlay = $EffectOverlay
@onready var _blind_vignette: BlindVignette = $BlindVignette
@onready var _game_over_overlay: GameOverOverlay = $GameOverOverlay
var _was_blinded: bool = false
var _was_frozen: bool = false
var _was_immune: bool = false
var _was_spied: bool = false
var _was_detecting: bool = false

var _global_power_armed: bool = false
var _action_locked: bool = false
var _armed_scope: String = ""

var _my_nickname := ""
var _opponent_nickname := ""
var _my_avatar_texture: Texture2D = null
var _opponent_avatar_texture: Texture2D = null
var _cached_is_my_turn: bool = false
var _cached_seconds_remaining: float = 0.0
var _my_inventory_cache: Array = []
var _cached_opponent_inventory: Array = []
var _navigation_started: bool = false

func _ready() -> void:
	leave_button.pressed.connect(_on_leave_button_pressed)
	if is_instance_valid(_inventory_panel):
		if not _inventory_panel.slot_pressed.is_connected(_on_inventory_slot_pressed):
			_inventory_panel.slot_pressed.connect(_on_inventory_slot_pressed)
		if not _inventory_panel.slot_drag_launch.is_connected(_on_inventory_slot_drag_launch):
			_inventory_panel.slot_drag_launch.connect(_on_inventory_slot_drag_launch)
		if not _inventory_panel.slot_drag_discard.is_connected(_on_inventory_slot_drag_discard):
			_inventory_panel.slot_drag_discard.connect(_on_inventory_slot_drag_discard)
	_game_over_overlay.home_requested.connect(_navigate_home)
	GameFactory.bind(self)
	resized.connect(_on_board_resized)
	_main_layout.resized.connect(_on_board_resized)
	_apply_board_90_percent.call_deferred()
	_apply_inventory_responsive.call_deferred()

func _on_board_resized() -> void:
	_apply_board_90_percent.call_deferred()
	_apply_inventory_responsive.call_deferred()

func _apply_inventory_responsive() -> void:
	if not is_instance_valid(_inventory_panel) or not is_instance_valid(_main_layout):
		return
	var layout_w: float = _main_layout.size.x
	if layout_w < 10.0:
		var vp := get_viewport_rect().size.x
		if vp > 10.0:
			layout_w = vp - 24.0
		else:
			layout_w = 456.0
	_inventory_panel.apply_responsive(layout_w)

func _apply_board_90_percent() -> void:
	if not is_instance_valid(board_view) or not is_instance_valid(_main_layout):
		return
	var layout_w: float = _main_layout.size.x
	if layout_w < 10.0:
		var vp := get_viewport_rect().size.x
		if vp > 10.0:
			layout_w = vp - 24.0
		else:
			layout_w = 456.0
	var avail: float = layout_w * 0.90
	var chrome: float = 16.0 + 8.0 + 9.0
	var cell_f: float = floor((avail - chrome) / 10.0)
	cell_f = clamp(cell_f, 30.0, 96.0)
	var cell := int(cell_f)
	var font_sz := clampi(int(cell * 0.42), 12, 18)
	var wrapper_w: float = 10.0 * float(cell) + chrome
	words_container_view.custom_minimum_size = Vector2(wrapper_w, 72)
	words_container_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	board_view.apply_responsive(layout_w, cell, font_sz)

func setup(view_model: GameViewModel, game_id: String, opponent_id: String, me_nickname: String, opponent_nickname: String, my_avatar: String = "", opponent_avatar: String = "") -> void:
	_view_model = view_model
	_my_nickname = me_nickname
	_opponent_nickname = opponent_nickname
	var assets: EquippableAssetService = ServiceRegistry.avatar_assets()
	EquippedAvatar.ensure_downloaded(assets, my_avatar)
	EquippedAvatar.ensure_downloaded(assets, opponent_avatar)
	_my_avatar_texture = EquippedAvatar.texture_for(assets, my_avatar) if not my_avatar.is_empty() else null
	_opponent_avatar_texture = EquippedAvatar.texture_for(assets, opponent_avatar) if not opponent_avatar.is_empty() else null
	if is_instance_valid(player_info_bar):
		player_info_bar.setup_players(me_nickname, opponent_nickname, _my_avatar_texture, _opponent_avatar_texture)
	_build_board_buttons()
	_connect_view_model()
	_view_model.start(game_id, opponent_id, my_avatar, opponent_avatar)

func _connect_view_model() -> void:
	_view_model.board_changed.connect(_on_board_changed)
	_view_model.words_changed.connect(_on_words_changed)
	_view_model.my_inventory_changed.connect(_on_my_inventory_changed)
	_view_model.opponent_inventory_changed.connect(_on_opponent_inventory_changed)
	_view_model.my_avatar_changed.connect(_on_my_avatar_changed)
	_view_model.opponent_avatar_changed.connect(_on_opponent_avatar_changed)
	_view_model.power_granted.connect(_on_power_granted)
	_view_model.turn_state_changed.connect(_on_turn_state_changed)
	_view_model.turn_timer_updated.connect(_on_turn_timer_updated)
	_view_model.action_lock_changed.connect(_on_action_lock_changed)
	_view_model.effect_state_changed.connect(_on_effect_state_changed)
	_view_model.game_ended.connect(_on_game_ended)
	_view_model.armed_power_changed.connect(_on_armed_power_changed)
	_view_model.defense_pulse_changed.connect(_on_defense_pulse_changed)
	_view_model.word_found_feedback.connect(_on_word_found_feedback)
	_view_model.trap_event_feedback.connect(_on_trap_event_feedback)
	_view_model.trap_animation_requested.connect(_on_trap_animation_requested)
	_view_model.selected_power_changed.connect(_on_selected_power_changed)

func _build_board_buttons() -> void:
	_cell_buttons = board_view.get_all_cells()
	if _cell_buttons.is_empty():
		await board_view.ready
		_cell_buttons = board_view.get_all_cells()
	for cell_position in _cell_buttons:
		var cv: CellView = _cell_buttons[cell_position] as CellView
		if cv != null and not cv.cell_pressed.is_connected(_on_cell_view_pressed):
			cv.cell_pressed.connect(_on_cell_view_pressed)

	for cell_position in _cell_buttons:
		_apply_cell_style(cell_position)

	_apply_board_90_percent.call_deferred()

func _on_cell_view_pressed(pos: Vector2i) -> void:
	_on_cell_pressed(pos.x, pos.y)

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
	if bv is CellView:
		(bv as CellView).shake()

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
	var bv = _cell_buttons.get(cell_position)
	if bv is CellView:
		var cv: CellView = bv
		var state := _view_model.get_cell_visual_state(cell_position.x, cell_position.y)
		var letter := _view_model.get_cell_letter(cell_position.x, cell_position.y)
		var block_colors: Array = []
		if state == GameViewModel.CELL_STATE_BLOCK_ME or state == GameViewModel.CELL_STATE_BLOCK_OPPONENT:
			block_colors = _view_model.get_block_click_colors(cell_position.x, cell_position.y)
			if block_colors.is_empty():
				var filled := _view_model.get_cell_block_filled(cell_position.x, cell_position.y)
				var owner_color := Color(0.5, 0.5, 0.5, 1)
				if filled > 0:
					owner_color = COLOR_BLUE if state == GameViewModel.CELL_STATE_BLOCK_ME else COLOR_ORANGE
				for i in filled:
					block_colors.append(owner_color)
				while block_colors.size() < 3:
					block_colors.append(Color.WHITE)
		var cw: float = cv.custom_minimum_size.x if cv.custom_minimum_size.x > 1.0 else 30.0
		cv.apply_state(state, letter, block_colors, cw)
func _animate_cell_reveal(cell_position: Vector2i) -> void:
	var bv = _cell_buttons.get(cell_position)
	if bv is CellView:
		(bv as CellView).animate_reveal(_apply_cell_style.bind(cell_position))

func _on_words_changed(words: Array) -> void:
	var items: Array = []
	for w in words:
		if not w is GameWord:
			continue
		var gw: GameWord = w
		var owner := _view_model.classify_word_owner(gw) if _view_model != null else ""
		items.append({
			"text": gw.word,
			"owner": owner,
			"found": gw.found,
			"found_by": gw.found_by_player_id,
		})
	words_container_view.update_words(items)

func _on_my_inventory_changed(inventory: Array) -> void:
	_my_inventory_cache = inventory
	var is_frozen: bool = _view_model != null and _view_model.is_frozen()
	if is_instance_valid(_inventory_panel):
		_inventory_panel.update_inventory(inventory, is_frozen)
	if is_instance_valid(player_info_bar):
		player_info_bar.set_my_inventory(inventory)

func _on_opponent_inventory_changed(inventory: Array) -> void:
	_cached_opponent_inventory = inventory
	if is_instance_valid(player_info_bar):
		player_info_bar.set_opponent_inventory(inventory)


func _on_my_avatar_changed(texture: Texture2D) -> void:
	_my_avatar_texture = texture
	if is_instance_valid(player_info_bar):
		player_info_bar.set_my_avatar(texture)


func _on_opponent_avatar_changed(texture: Texture2D) -> void:
	_opponent_avatar_texture = texture
	if is_instance_valid(player_info_bar):
		player_info_bar.set_opponent_avatar(texture)

func _on_defense_pulse_changed(pulse_ids: Array) -> void:
	if is_instance_valid(_inventory_panel):
		_inventory_panel.set_defense_pulse(pulse_ids)

func _on_power_granted(power: GamePower) -> void:
	if is_instance_valid(_inventory_panel):
		_inventory_panel.flash_grant(power.id)

func _on_inventory_slot_pressed(index: int) -> void:
	var power_id: String = _inventory_panel.get_power_id_at(index) if is_instance_valid(_inventory_panel) else ""
	if power_id.is_empty():
		return
	_view_model.on_power_clicked(power_id)

func _on_inventory_slot_drag_launch(index: int) -> void:
	await (Engine.get_main_loop() as SceneTree).create_timer(0.3).timeout
	if is_instance_valid(_view_model):
		_view_model.confirm_armed_global_power()

func _on_inventory_slot_drag_discard(index: int) -> void:
	await (Engine.get_main_loop() as SceneTree).create_timer(0.3).timeout
	if is_instance_valid(_view_model):
		_view_model.discard_armed_power()

func _on_armed_power_changed(_power_id: String, _power_type: String, scope: String) -> void:
	_armed_scope = scope
	if is_instance_valid(_inventory_panel) and _view_model != null:
		_inventory_panel.set_armed(_view_model.selected_power_id(), scope, _view_model.is_frozen(), _view_model.is_blinded())
	if scope == GamePowerCatalog.SCOPE_CELL:
		_global_power_armed = false
		_update_board_interactivity()
		board_view.set_board_pulse(true)
	elif scope == GamePowerCatalog.SCOPE_GLOBAL:
		_global_power_armed = true
		board_view.set_board_pulse(false)
		_update_board_interactivity()
	else:
		_global_power_armed = false
		board_view.set_board_pulse(false)
		_update_board_interactivity()

func _on_turn_state_changed(is_my_turn: bool) -> void:
	_cached_is_my_turn = is_my_turn
	if is_instance_valid(player_info_bar):
		player_info_bar.set_turn(is_my_turn)

func _on_turn_timer_updated(seconds_remaining: float) -> void:
	_cached_seconds_remaining = seconds_remaining
	if is_instance_valid(player_info_bar):
		player_info_bar.set_turn_seconds(seconds_remaining)

func _on_effect_state_changed() -> void:
	_update_board_interactivity()
	_refresh_all_cell_styles()
	if is_instance_valid(_inventory_panel) and _view_model != null:
		_inventory_panel.refresh_for_effect(_view_model.is_frozen(), _view_model.is_blinded())
		_inventory_panel.set_defense_pulse(_view_model.get_defense_pulse_ids())

	if _view_model == null:
		return

	var blinded_now := _view_model.is_blinded()
	var frozen_now := _view_model.is_frozen()
	var immune_now := _view_model.is_immune()
	var spied_now := _view_model.is_spied() if _view_model.has_method("is_spied") else false
	var detecting_now := _view_model.is_detecting_traps() if _view_model.has_method("is_detecting_traps") else false

	var has_wash := false
	if frozen_now:
		_effect_overlay.show_with_color(EFFECT_FREEZE_COLOR)
		has_wash = true
	elif immune_now:
		_effect_overlay.show_with_color(EFFECT_IMMUNITY_COLOR)
		has_wash = true
	elif detecting_now and not blinded_now:
		_effect_overlay.show_with_color(EFFECT_DETECT_WASH)
		has_wash = true
	elif spied_now and not blinded_now:
		_effect_overlay.show_with_color(EFFECT_SPY_WASH)
		has_wash = true

	if blinded_now:
		_blind_vignette.show_vignette()
		if has_wash and is_instance_valid(_blind_vignette):
			_blind_vignette.modulate.a = 0.7
	else:
		_blind_vignette.hide_vignette()

	if not has_wash and not blinded_now:
		if _was_blinded or _was_frozen or _was_immune or _was_spied or _was_detecting:
			_effect_overlay.hide_overlay()
		else:
			_effect_overlay.hide_overlay()
		if _was_blinded and not blinded_now:
			_effect_overlay.flash(EFFECT_LANTERN_FLASH, 0.5)
		elif _was_frozen and not frozen_now:
			_effect_overlay.flash(EFFECT_UNFREEZE_HOT, UNFREEZE_HOT_HOLD)
		elif _was_immune and not immune_now:
			_effect_overlay.flash(EFFECT_IMMUNITY_END_FLASH, 0.5)

	_was_blinded = blinded_now
	_was_frozen = frozen_now
	_was_immune = immune_now
	_was_spied = spied_now
	_was_detecting = detecting_now

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

func _pop_trap_cell(cell_position: Vector2i) -> void:
	var bv = _cell_buttons.get(cell_position)
	if bv is CellView:
		(bv as CellView).pop_trap()
func _break_block_cell(cell_position: Vector2i) -> void:
	var bv = _cell_buttons.get(cell_position)
	if bv is CellView:
		(bv as CellView).break_block()
func _restyle_cell(cell_position: Vector2i) -> void:
	if not _cell_buttons.has(cell_position):
		return

	_apply_cell_style(cell_position)
	_last_cell_state[cell_position] = _view_model.get_cell_visual_state(cell_position.x, cell_position.y)

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
		words_container_view.force_refresh_signature()
		_on_words_changed(_view_model.words())

	var pulse_cells: Array[Vector2i] = []
	for c in cells:
		if c is Vector2i and _cell_buttons.has(c):
			pulse_cells.append(c)
	if not pulse_cells.is_empty():
		board_view.play_word_pulse_sequence(pulse_cells)

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
	_pop_trap_cell(Vector2i(x, y))

func _on_selected_power_changed(_power_id: String) -> void:
	if is_instance_valid(_inventory_panel) and _view_model != null:
		_inventory_panel.set_armed(_view_model.selected_power_id(), _armed_scope, _view_model.is_frozen(), _view_model.is_blinded())
func _on_action_lock_changed(is_locked: bool) -> void:
	_action_locked = is_locked
	_update_board_interactivity()

func _update_board_interactivity() -> void:
	var board_logical_disabled := _global_power_armed or _action_locked or (_view_model != null and _view_model.is_game_over())
	if _view_model != null and _view_model.is_frozen() and _armed_scope == GamePowerCatalog.SCOPE_GLOBAL:
		var selected_id := _view_model.selected_power_id()
		for p in _my_inventory_cache:
			if p is GamePower and (p as GamePower).id == selected_id and GamePowerCatalog.can_use_while_frozen((p as GamePower).type):
				board_logical_disabled = false
				break

	var is_over := _view_model != null and _view_model.is_game_over()
	var board_visual_dimmed := _global_power_armed and not is_over
	if not is_over and _view_model != null and _view_model.is_frozen() and _armed_scope == GamePowerCatalog.SCOPE_GLOBAL:
		var sel := _view_model.selected_power_id()
		for p in _my_inventory_cache:
			if p is GamePower and (p as GamePower).id == sel and GamePowerCatalog.can_use_while_frozen((p as GamePower).type):
				board_visual_dimmed = false
				break

	var revealed_states: Dictionary = {}
	for cell_position in _cell_buttons:
		var vs := _view_model.get_cell_visual_state(cell_position.x, cell_position.y)
		var cell_revealed := vs == GameViewModel.CELL_STATE_REVEALED_ME or vs == GameViewModel.CELL_STATE_REVEALED_OPPONENT or vs == GameViewModel.CELL_STATE_CLAIMED_ME or vs == GameViewModel.CELL_STATE_CLAIMED_OPPONENT or vs == GameViewModel.CELL_STATE_CLAIMED_BOTH
		revealed_states[cell_position] = cell_revealed
	board_view.set_interactivity(board_logical_disabled, revealed_states)
	if is_instance_valid(board_view):
		board_view.modulate = Color(1, 1, 1, 0.6) if board_visual_dimmed else Color.WHITE

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
	_game_over_overlay.show_result(_is_winner, _title, _subtitle)

func _navigate_home() -> void:
	if _navigation_started:
		return

	_navigation_started = true
	_view_model.go_to_home()
