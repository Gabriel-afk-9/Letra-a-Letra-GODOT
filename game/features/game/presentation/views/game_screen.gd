extends Control
class_name GameScreen


const BOARD_SIZE := 10
const CELL_SIZE := Vector2(22, 22)

const COLOR_BLUE := Color(0.101960786, 0.57254905, 0.9019608, 1)
const COLOR_ORANGE := Color(0.9529412, 0.52156866, 0.09411765, 1)

const CELL_BORDER_WIDTH := 1
const CELL_CORNER_RADIUS := 5

const COLOR_WHITE := Color(1, 1, 1, 1)
const COLOR_HIDDEN_BORDER := Color(1, 1, 1, 0.6431373)
const COLOR_TEXT_DARK := Color(0.15, 0.15, 0.15, 1)
const COLOR_TEXT_NEUTRAL := Color(0.45, 0.45, 0.45, 1)


@onready var my_player_card = $MarginContainer/MainLayout/TopBar/MyPlayerCard
@onready var turn_label: Label = $MarginContainer/MainLayout/TopBar/TurnLabel
@onready var opponent_player_card = $MarginContainer/MainLayout/TopBar/OpponentPlayerCard
@onready var words_container: HFlowContainer = $MarginContainer/MainLayout/WordsContainer
@onready var board_grid: GridContainer = $MarginContainer/MainLayout/BoardGrid
@onready var leave_button: Button = $MarginContainer/MainLayout/BottomBar/LeaveButton
@onready var status_label: Label = $MarginContainer/MainLayout/BottomBar/StatusLabel
@onready var inventory_container: HBoxContainer = $MarginContainer/MainLayout/InventoryPanel/InventoryContainer
@onready var inventory_count_label: Label = $MarginContainer/MainLayout/TopBar/PlayerCardHost/CountLabel

var _view_model: GameViewModel
var _cell_buttons: Dictionary = {}

var _cached_is_my_turn: bool = false
var _cached_seconds_remaining: float = 0.0

var _my_nickname := ""
var _opponent_nickname := ""

var _cached_my_inventory: Array = []
var _cached_opponent_inventory: Array = []
var _inventory_slots: Array = []
var _icon_cache: Dictionary = {}

var _navigation_started: bool = false


func _ready() -> void:
	leave_button.pressed.connect(_on_leave_button_pressed)
	_build_inventory_slots()
	GameFactory.bind(self)


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
	_view_model.turn_state_changed.connect(_on_turn_state_changed)
	_view_model.turn_timer_updated.connect(_on_turn_timer_updated)
	_view_model.action_lock_changed.connect(_on_action_lock_changed)
	_view_model.error_changed.connect(_on_error_changed)
	_view_model.game_ended.connect(_on_game_ended)


# Internal — tabuleiro

func _build_board_buttons() -> void:
	board_grid.columns = BOARD_SIZE
	board_grid.add_theme_constant_override("h_separation", 1)
	board_grid.add_theme_constant_override("v_separation", 1)

	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			var button := Button.new()
			button.custom_minimum_size = CELL_SIZE
			button.add_theme_font_size_override("font_size", 10)
			button.pressed.connect(_on_cell_pressed.bind(x, y))
			board_grid.add_child(button)
			_cell_buttons[Vector2i(x, y)] = button

	# Aplica o estilo oculto já na criação: além de pintar o estado inicial,
	# garante que o StyleBoxFlat do "normal" seja o que define o tamanho mínimo
	# do botão (sem margens de conteúdo do tema), mantendo a grade compacta.
	for cell_position in _cell_buttons:
		_apply_cell_style(cell_position)


func _on_cell_pressed(x: int, y: int) -> void:
	_view_model.on_cell_clicked(x, y)


func _on_board_changed(_board: GameBoard) -> void:
	for x in BOARD_SIZE:
		for y in BOARD_SIZE:
			_apply_cell_style(Vector2i(x, y))


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
			_style_cell(button, COLOR_WHITE, COLOR_HIDDEN_BORDER, COLOR_TEXT_DARK)


func _style_cell(button: Button, background: Color, border: Color, font: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = CELL_BORDER_WIDTH
	style.border_width_top = CELL_BORDER_WIDTH
	style.border_width_right = CELL_BORDER_WIDTH
	style.border_width_bottom = CELL_BORDER_WIDTH
	style.set_corner_radius_all(CELL_CORNER_RADIUS)

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

		match _view_model.classify_word_owner(word):
			"me":
				label.add_theme_color_override("font_color", COLOR_BLUE)
			"opponent":
				label.add_theme_color_override("font_color", COLOR_ORANGE)
			_:
				label.add_theme_color_override("font_color", COLOR_TEXT_NEUTRAL)

		words_container.add_child(label)


# Internal — inventário
#
# O inventário não vive mais dentro dos PlayerCards: há um único InventoryPanel
# no MainLayout que exibe o inventário do jogador da vez (mesma separação
# me/opponent já feita pelo UseCase/ViewModel). A View só cacheia os dois
# inventários e reage ao turno para escolher qual exibir.

func _on_my_inventory_changed(inventory: Array) -> void:
	_cached_my_inventory = inventory
	_update_inventory_panel()


func _on_opponent_inventory_changed(inventory: Array) -> void:
	_cached_opponent_inventory = inventory
	_update_inventory_panel()


func _update_inventory_panel() -> void:
	var inventory := _cached_my_inventory if _cached_is_my_turn else _cached_opponent_inventory
	var occupied := 0

	for index in GamePlayerState.INVENTORY_SIZE:
		if index >= _inventory_slots.size():
			continue

		var slot_variant = _inventory_slots[index]

		if not slot_variant is TextureRect:
			continue

		var slot: TextureRect = slot_variant
		var power = inventory[index] if index < inventory.size() else null

		if power is GamePower:
			slot.texture = _power_icon(power.type)
			occupied += 1
		else:
			slot.texture = null

	if occupied > 0:
		inventory_count_label.text = "● ".repeat(occupied).trim_suffix(" ")
		inventory_count_label.show()
	else:
		inventory_count_label.text = ""
		inventory_count_label.hide()


func _build_inventory_slots() -> void:
	for index in GamePlayerState.INVENTORY_SIZE:
		var slot_frame := PanelContainer.new()
		slot_frame.custom_minimum_size = Vector2(24, 24)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.2)
		style.set_corner_radius_all(4)
		slot_frame.add_theme_stylebox_override("panel", style)

		var slot_icon := TextureRect.new()
		slot_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot_frame.add_child(slot_icon)

		inventory_container.add_child(slot_frame)
		_inventory_slots.append(slot_icon)


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


# Apenas o card do jogador que está com a vez fica visível — o outro é
# ocultado via clear() (que chama hide()), liberando o espaço no TopBar.
# Decisão vem do estado de turno do ViewModel; a View só reage ao sinal.

func _update_player_cards() -> void:
	if _cached_is_my_turn:
		my_player_card.show_local(_my_nickname)
		opponent_player_card.clear()
	else:
		opponent_player_card.show_opponent(_opponent_nickname)
		my_player_card.clear()


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
	board_grid.modulate = Color(1, 1, 1, 0.5) if is_locked else Color(1, 1, 1, 1)


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


# O backend já encerrou a partida (oponente saiu, GAME_OVER ou inatividade).
# Encerra a Game local e retorna ao fluxo inicial. NÃO envia LEFT_GAME: o
# evento recebido já representa o encerramento da participação do oponente.

func _on_game_ended(_is_winner: bool, _title: String, _subtitle: String) -> void:
	leave_button.disabled = true
	_navigate_home()


# Participante B pode receber PARTICIPANT_LEAVE e GAME_OVER em sequência — ambos
# disparam game_ended. A navegação é guardada para não trocar de cena duas vezes.

func _navigate_home() -> void:
	if _navigation_started:
		return

	_navigation_started = true
	_view_model.go_to_home()
