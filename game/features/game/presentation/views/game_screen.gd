extends Control
class_name GameScreen


const BOARD_SIZE := 10
const CELL_SIZE := Vector2(30, 30)

const COLOR_BLUE := Color(0.101960786, 0.57254905, 0.9019608, 1)
const COLOR_ORANGE := Color(0.9529412, 0.52156866, 0.09411765, 1)

const CELL_BORDER_WIDTH := 2
const CELL_CORNER_RADIUS := 5

const COLOR_WHITE := Color(1, 1, 1, 1)
const COLOR_HIDDEN_BORDER := Color(1, 1, 1, 0.6431373)
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


@onready var my_card_wrapper: Control = $MarginContainer/MainLayout/TopBar/CardsCenter/MyCardWrapper
@onready var opponent_card_wrapper: Control = $MarginContainer/MainLayout/TopBar/CardsCenter/OpponentCardWrapper
@onready var my_player_card = $MarginContainer/MainLayout/TopBar/CardsCenter/MyCardWrapper/MyPlayerCard
@onready var my_power_dots: HBoxContainer = $MarginContainer/MainLayout/TopBar/CardsCenter/MyCardWrapper/MyPowerDots
@onready var opponent_player_card = $MarginContainer/MainLayout/TopBar/CardsCenter/OpponentCardWrapper/OpponentPlayerCard
@onready var opponent_power_dots: HBoxContainer = $MarginContainer/MainLayout/TopBar/CardsCenter/OpponentCardWrapper/OpponentPowerDots
@onready var turn_label: Label = $MarginContainer/MainLayout/TopBar/TurnLabel
@onready var words_container: HFlowContainer = $MarginContainer/MainLayout/WordsContainer
@onready var board_grid: GridContainer = $MarginContainer/MainLayout/BoardGrid
@onready var leave_button: Button = $MarginContainer/MainLayout/BottomBar/LeaveButton
@onready var status_label: Label = $MarginContainer/MainLayout/BottomBar/StatusLabel
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
	
	# WordsContainer centralizado
	words_container.alignment = FlowContainer.ALIGNMENT_CENTER
	
	# 1. Envelopar WordsContainer em painel preto
	_wrap_words_container()
	
	# 2. Envelopar BoardGrid em painel branco com borda preta
	_wrap_board_grid()
	
	for i in _inventory_slots.size():
		var slot: TextureButton = _inventory_slots[i]
		slot.ignore_texture_size = true
		slot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		slot.pressed.connect(_on_power_slot_pressed.bind(i))
		slot.gui_input.connect(_on_inventory_icon_gui_input.bind(i))
	
	GameFactory.bind(self)


# 1. WordsContainer — wrapper em PanelContainer preto
func _wrap_words_container() -> void:
	var parent := words_container.get_parent()
	if not parent:
		return
	
	var wrapper := PanelContainer.new()
	wrapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 12
	style.content_margin_top = 12
	style.content_margin_right = 12
	style.content_margin_bottom = 12
	wrapper.add_theme_stylebox_override("panel", style)
	
	# Substitui visualmente: remove words_container do pai, adiciona wrapper no lugar, coloca words_container dentro do wrapper
	var idx: int = parent.get_children().find(words_container)
	parent.remove_child(words_container)
	parent.add_child(wrapper)
	parent.move_child(wrapper, idx)
	wrapper.add_child(words_container)


# 2. BoardGrid — wrapper em PanelContainer branco com borda preta
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


# Internal — wiring

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
	_view_model.game_ended.connect(_on_game_ended)
	_view_model.armed_power_changed.connect(_on_armed_power_changed)


# Internal — tabuleiro

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


func _on_cell_pressed(x: int, y: int) -> void:
	_view_model.on_cell_clicked(x, y)


func _on_board_changed(_board: GameBoard) -> void:
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var pos := Vector2i(x, y)
			var new_state := _view_model.get_cell_visual_state(x, y)
			if _last_cell_state.get(pos) != new_state:
				_apply_cell_style(pos)
				_last_cell_state[pos] = new_state

	# Células podem ter mudado de estado (ex: reveladas) — reavalia
	# o input individual delas junto com o gate global.
	_update_board_interactivity()


func _apply_cell_style(cell_position: Vector2i) -> void:
	var button_variant = _cell_buttons.get(cell_position)

	if not button_variant is Button:
		return

	var button: Button = button_variant
	var state := _view_model.get_cell_visual_state(cell_position.x, cell_position.y)

	button.text = _view_model.get_cell_letter(cell_position.x, cell_position.y)

	match state:
		GameViewModel.CELL_STATE_REVEALED_ME:
			_style_cell(button, COLOR_WHITE, COLOR_BLUE, COLOR_TEXT_DARK)
		GameViewModel.CELL_STATE_REVEALED_OPPONENT:
			_style_cell(button, COLOR_WHITE, COLOR_ORANGE, COLOR_TEXT_DARK)
		GameViewModel.CELL_STATE_CLAIMED_ME:
			_style_cell(button, COLOR_BLUE, COLOR_BLUE, COLOR_WHITE)
		GameViewModel.CELL_STATE_CLAIMED_OPPONENT:
			_style_cell(button, COLOR_ORANGE, COLOR_ORANGE, COLOR_WHITE)
		_:
			_style_cell(button, COLOR_WHITE, Color(0, 0, 0, 0), COLOR_TEXT_DARK)


func _style_cell(button: Button, background: Color, state_shadow_color: Color, font: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(0, 0, 0, 1)
	style.border_width_left = CELL_BORDER_WIDTH
	style.border_width_top = CELL_BORDER_WIDTH
	style.border_width_right = CELL_BORDER_WIDTH
	style.border_width_bottom = CELL_BORDER_WIDTH
	style.set_corner_radius_all(CELL_CORNER_RADIUS)

	style.shadow_color = state_shadow_color
	style.shadow_size = 0 if state_shadow_color.a == 0 else 3

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_color_override("font_color", font)
	button.add_theme_color_override("font_pressed_color", font)


# Internal — palavras

func _on_words_changed(words: Array) -> void:
	_rebuild_words(words)



func _rebuild_words(words: Array) -> void:
	for child in words_container.get_children():
		child.queue_free()

	for word_variant in words:
		if not word_variant is GameWord:
			continue

		var word: GameWord = word_variant
		var label := Label.new()
		label.text = word.word
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

		words_container.add_child(label)


# Internal — inventário

func _on_my_inventory_changed(inventory: Array) -> void:
	_cached_my_inventory = inventory
	_update_inventory_panel()


func _on_opponent_inventory_changed(inventory: Array) -> void:
	_cached_opponent_inventory = inventory
	_update_opponent_power_dots()


# A barra detalhada de inventário (5 slots grandes) SEMPRE mostra os poderes do
# jogador local, independentemente de quem está na vez. Já a contagem do
# oponente (quantidade, não quais) aparece nas bolinhas sobre o card dele.
# Os 5 slots são nós fixos na cena (quantidade fixa e pequena), enquanto
# tabuleiro (100 células) e palavras (quantidade variável por partida) continuam
# gerados por código — muitos/variáveis demais para autoria manual.

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
			# Slot com poder: borda sólida branca sutil no frame (PanelContainer)
			var solid_style := StyleBoxFlat.new()
			solid_style.bg_color = Color(0, 0, 0, 0.4)
			solid_style.border_width_left = 2
			solid_style.border_width_top = 2
			solid_style.border_width_right = 2
			solid_style.border_width_bottom = 2
			solid_style.border_color = Color(1, 1, 1, 0.3)
			solid_style.corner_radius_top_left = 6
			solid_style.corner_radius_top_right = 6
			solid_style.corner_radius_bottom_right = 6
			solid_style.corner_radius_bottom_left = 6
			solid_style.content_margin_left = 4
			solid_style.content_margin_top = 4
			solid_style.content_margin_right = 4
			solid_style.content_margin_bottom = 4
			frame.add_theme_stylebox_override("panel", solid_style)
			# Remove dashed border script if present
			if frame.get_script():
				frame.set_script(null)
		else:
			slot.texture_normal = null
			# Slot vazio: borda tracejada no frame (PanelContainer) via script preload
			if frame.get_script() != DASHED_SLOT_FRAME_SCRIPT:
				frame.set_script(DASHED_SLOT_FRAME_SCRIPT)
			# Ensure no solid StyleBoxFlat overrides the custom drawing
			var empty_style := StyleBoxFlat.new()
			empty_style.bg_color = Color(0, 0, 0, 0)
			frame.add_theme_stylebox_override("panel", empty_style)

		# Icon (TextureButton) styling - keep simple, no border needed since frame handles it
		var icon_style := StyleBoxFlat.new()
		icon_style.bg_color = Color(0, 0, 0, 0)
		icon_style.content_margin_left = 4
		icon_style.content_margin_top = 4
		icon_style.content_margin_right = 4
		icon_style.content_margin_bottom = 4
		slot.add_theme_stylebox_override("normal", icon_style)
		slot.add_theme_stylebox_override("hover", icon_style)
		slot.add_theme_stylebox_override("pressed", icon_style)

	# Atualizar destaque do poder armado (se houver)
	_update_armed_power_highlight()

	_update_power_dots(_my_dots, _cached_my_inventory)


func _update_armed_power_highlight() -> void:
	var armed_id := _view_model.selected_power_id()
	for index in _inventory_slots.size():
		var slot_variant = _inventory_slots[index]
		if not slot_variant is TextureButton:
			continue
		var slot: TextureButton = slot_variant
		var power = _cached_my_inventory[index] if index < _cached_my_inventory.size() else null
		
		if power is GamePower and power.id == armed_id:
			# Poder armado: destaque amarelo
			slot.modulate = Color(1, 1, 0.2, 1)
		else:
			# Normal
			slot.modulate = Color(1, 1, 1, 1)


func _on_power_slot_pressed(slot_index: int) -> void:
	if slot_index >= _cached_my_inventory.size():
		return
	var power = _cached_my_inventory[slot_index]
	if not (power is GamePower):
		return
	_view_model.on_power_clicked(power.id)


# Feedback visual de poder novo no inventário (adaptado do "anim-enter" do MVP):
# pulso de scale + flash quente no slot correspondente ao id recebido. Chega
# DEPOIS de my_inventory_changed, então _cached_my_inventory já contém o poder.
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


# Gesto de deslizar pra cima no ícone de inventário confirma o disparo de um
# poder GLOBAL armado (o clique simples apenas arma/desarma). Poderes CELL não
# reagem ao gesto — a confirmação deles é o clique na célula.
func _on_inventory_icon_gui_input(event: InputEvent, slot_index: int) -> void:
	if slot_index >= _cached_my_inventory.size():
		return

	var power = _cached_my_inventory[slot_index]
	if not (power is GamePower):
		return

	if power.id != _view_model.selected_power_id():
		return

	if _armed_scope != GamePowerCatalog.SCOPE_GLOBAL:
		return

	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_drag_start_y = event.position.y
			_dragging_slot_index = slot_index
		else:
			_dragging_slot_index = -1
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if _dragging_slot_index != slot_index:
			return

		if event.position.y - _drag_start_y < -GLOBAL_SWIPE_THRESHOLD_PX:
			_dragging_slot_index = -1
			_view_model.confirm_armed_global_power()


func _on_armed_power_changed(_power_id: String, _power_type: String, scope: String) -> void:
	_armed_scope = scope
	_update_armed_power_highlight()

	if scope == GamePowerCatalog.SCOPE_CELL:
		# Poder CELL armado: pulso na borda do tabuleiro (aguardando clique)
		_global_power_armed = false
		_update_board_interactivity()
		_start_board_pulse()
	elif scope == GamePowerCatalog.SCOPE_GLOBAL:
		# Poder GLOBAL armado: tabuleiro desabilitado (aguardando gesto de swipe)
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

	style.shadow_color = COLOR_BLUE
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


func _update_power_dots(dots: Array, inventory: Array) -> void:
	var occupied := _count_occupied(inventory)

	for index in dots.size():
		var dot_variant = dots[index]

		if not dot_variant is Panel:
			continue

		var dot: Panel = dot_variant
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(5)

		if index < occupied:
			style.bg_color = Color(1, 1, 1, 0.95)
		else:
			style.bg_color = Color(0.5, 0.5, 0.5, 0.6)

		dot.add_theme_stylebox_override("panel", style)


func _power_icon(power_type: String) -> Texture2D:
	if _icon_cache.has(power_type):
		return _icon_cache[power_type]

	var path = PlayerCard.POWER_ICON_PATHS.get(power_type)

	if path == null:
		return null

	var texture := load(str(path)) as Texture2D
	_icon_cache[power_type] = texture

	return texture


# Internal — turno

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

	# Fade de entrada no card que acabou de aparecer (animado por fora,
	# sem tocar em PlayerCard.tscn/player_card.gd que são compartilhados).
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


# Internal — trava de ação e erro

func _on_action_lock_changed(is_locked: bool) -> void:
	_action_locked = is_locked
	_update_board_interactivity()


# Combina trava de ação e poder GLOBAL armado num único estado visual —
# nenhum dos dois sobrescreve o outro. O mouse_filter no board_grid sozinho
# não basta: os botões-filhos têm hit test próprio, então cada célula
# também recebe MOUSE_FILTER_IGNORE enquanto desabilitada. Além disso,
# células já reveladas ficam desabilitadas INDIVIDUALMENTE (o backend
# rejeita REVEAL nelas com "already been revealed") — o estado revelado
# é lido do viewmodel via get_cell_visual_state (todo estado != HIDDEN
# implica célula revelada), composto com o gate global sem duplicá-lo.
func _update_board_interactivity() -> void:
	var board_disabled := _global_power_armed or _action_locked

	board_grid.modulate = BOARD_DIMMED_MODULATE if board_disabled else COLOR_WHITE
	board_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE if board_disabled else Control.MOUSE_FILTER_STOP

	for cell_position in _cell_buttons:
		var button_variant = _cell_buttons.get(cell_position)

		if not button_variant is Button:
			continue

		var button: Button = button_variant
		var cell_revealed := _view_model.get_cell_visual_state(cell_position.x, cell_position.y) != GameViewModel.CELL_STATE_HIDDEN
		var cell_disabled := board_disabled or cell_revealed

		button.mouse_filter = Control.MOUSE_FILTER_IGNORE if cell_disabled else Control.MOUSE_FILTER_STOP


func _on_error_changed(message: String) -> void:
	if message.is_empty():
		status_label.hide()
		status_label.text = ""
	else:
		status_label.text = message
		status_label.show()


# Internal — sair

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

	# CenterContainer ocupa toda a tela e centraliza o conteúdo
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
