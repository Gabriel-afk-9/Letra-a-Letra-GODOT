extends BaseViewModel
class_name GameViewModel


const REASON_WORDS := "WORDS"
const REASON_OPPONENT_LEFT := "OPPONENT_LEFT"
const REASON_INACTIVITY := "INACTIVITY"

const CELL_STATE_HIDDEN := "HIDDEN"
const CELL_STATE_REVEALED_ME := "REVEALED_ME"
const CELL_STATE_REVEALED_OPPONENT := "REVEALED_OPPONENT"
const CELL_STATE_CLAIMED_ME := "CLAIMED_ME"
const CELL_STATE_CLAIMED_OPPONENT := "CLAIMED_OPPONENT"

const FREEZE_TURNS_DEFAULT := 3
const IMMUNITY_TURNS_DEFAULT := 5
const ACTION_LOCK_TIMEOUT_SECONDS := 3.0
const TURN_TIMER_TICK_SECONDS := 0.5


signal board_changed(board: GameBoard)
signal words_changed(words: Array)
signal my_inventory_changed(inventory: Array)
signal opponent_inventory_changed(inventory: Array)
signal power_granted(power: GamePower)
signal turn_state_changed(is_my_turn: bool)
signal turn_timer_updated(seconds_remaining: float)
signal action_lock_changed(is_locked: bool)
signal effect_state_changed
signal word_found_feedback(cells: Array, is_me: bool)
signal trap_event_feedback(event_name: String, x: int, y: int)
signal trap_animation_requested(x: int, y: int)
signal notification_requested(message: String)
signal selected_power_changed(power_id: String)
signal armed_power_changed(power_id: String, power_type: String, scope: String)
signal game_ended(is_winner: bool, title: String, subtitle: String)

var _usecase: GameUseCase
var _navigation: NavigationService

var _board: GameBoard = null
var _words: Array = []
var _my_inventory: Array = []
var _opponent_inventory: Array = []
var _is_my_turn: bool = false
var _turn_ends_at: String = ""
var _last_turn_player_id: String = ""
var _is_action_locked: bool = false
var _action_lock_generation: int = 0
var _turn_timer_generation: int = 0

var _is_frozen: bool = false
var _freeze_turns_left: int = 0
var _is_immune: bool = false
var _immunity_turns_left: int = 0
var _is_blinded: bool = false
var _is_detecting_traps: bool = false
var _is_spied: bool = false

var _armed_power_id: String = ""
var _armed_power_type: String = ""

var _cells_claimed_by_me: Array[Vector2i] = []
var _cells_claimed_by_opponent: Array[Vector2i] = []


func _init(usecase: GameUseCase, navigation: NavigationService) -> void:
	_usecase = usecase
	_navigation = navigation

	_usecase.board_updated.connect(_on_board_updated)
	_usecase.words_updated.connect(_on_words_updated)
	_usecase.my_inventory_updated.connect(_on_my_inventory_updated)
	_usecase.opponent_inventory_updated.connect(_on_opponent_inventory_updated)
	_usecase.power_granted.connect(_on_power_granted)
	_usecase.turn_changed.connect(_on_turn_changed)
	_usecase.my_cell_revealed.connect(_on_my_cell_revealed)
	_usecase.word_found.connect(_on_word_found)
	_usecase.trap_event.connect(_on_trap_event)
	_usecase.my_effect_event.connect(_on_my_effect_event)
	_usecase.game_over.connect(_on_game_over)
	_usecase.connection_lost.connect(_on_connection_lost)
	_usecase.action_rejected.connect(_on_action_rejected)


# Public API

func start(game_id: String, opponent_id: String) -> void:
	_set_loading(true)
	_usecase.start(game_id, opponent_id)
	_set_loading(false)


func on_cell_clicked(x: int, y: int) -> void:
	if _is_action_locked:
		return

	if not _armed_power_id.is_empty() and GamePowerCatalog.get_scope(_armed_power_type) == GamePowerCatalog.SCOPE_CELL:
		_usecase.use_power_on_cell(_armed_power_id, _armed_power_type, x, y)
		# Desarmar após uso
		_armed_power_id = ""
		_armed_power_type = ""
		selected_power_changed.emit("")
		armed_power_changed.emit("", "", "")
	else:
		_usecase.reveal_cell(x, y)

	_lock_action()


func select_power(power_id: String, power_type: String) -> void:
	if _is_action_locked:
		return

	if GamePowerCatalog.get_scope(power_type) == GamePowerCatalog.SCOPE_GLOBAL:
		_usecase.use_global_power(power_id, power_type)
		_lock_action()
		return

	_armed_power_id = power_id
	_armed_power_type = power_type
	selected_power_changed.emit(power_id)
	armed_power_changed.emit(power_id, power_type, GamePowerCatalog.get_scope(power_type))


func on_power_clicked(power_id: String) -> void:
	if _is_action_locked:
		return

	# Buscar o poder no inventário do jogador local
	var power: GamePower = null
	for p in _my_inventory:
		if p is GamePower and p.id == power_id:
			power = p
			break

	if power == null:
		return

	# Bloqueio: se congelado, só permite poderes que podem ser usados congelado
	if _is_frozen and not GamePowerCatalog.can_use_while_frozen(power.type):
		return

	var scope := GamePowerCatalog.get_scope(power.type)

	# GLOBAL agora também apenas arma — o disparo real acontece em
	# confirm_armed_global_power() (confirmação da View numa próxima etapa).
	# CELL mantém o comportamento: executa no clique na célula.
	if _armed_power_id == power_id:
		clear_selected_power()
		return

	_armed_power_id = power_id
	_armed_power_type = power.type
	selected_power_changed.emit(power_id)
	armed_power_changed.emit(power_id, power.type, scope)


func confirm_armed_global_power() -> void:
	if _armed_power_id.is_empty():
		return

	if GamePowerCatalog.get_scope(_armed_power_type) != GamePowerCatalog.SCOPE_GLOBAL:
		return

	_usecase.use_global_power(_armed_power_id, _armed_power_type)
	_lock_action()
	clear_selected_power()


func clear_selected_power() -> void:
	_armed_power_id = ""
	_armed_power_type = ""
	selected_power_changed.emit("")
	armed_power_changed.emit("", "", "")


func discard_power(power_id: String) -> void:
	_usecase.discard_power(power_id)


func leave_game() -> void:
	_usecase.leave_game()


func go_to_home() -> void:
	_navigation.go_to(AppRoutes.HOME)


func board() -> GameBoard:
	return _board

func words() -> Array:
	return _words

func my_inventory() -> Array:
	return _my_inventory

func opponent_inventory() -> Array:
	return _opponent_inventory

func is_my_turn() -> bool:
	return _is_my_turn

func is_action_locked() -> bool:
	return _is_action_locked

func is_frozen() -> bool:
	return _is_frozen

func is_immune() -> bool:
	return _is_immune

func is_blinded() -> bool:
	return _is_blinded

func is_detecting_traps() -> bool:
	return _is_detecting_traps

func is_spied() -> bool:
	return _is_spied

func selected_power_id() -> String:
	return _armed_power_id


# Estado visual de cada célula — toda a decisão de cor vive aqui, a View só
# aplica estilo. A ordem importa: células reivindicadas (palavra completa)
# têm precedência sobre células apenas reveladas.

func get_cell_visual_state(x: int, y: int) -> String:
	var cell_position := Vector2i(x, y)

	if _cells_claimed_by_me.has(cell_position):
		return CELL_STATE_CLAIMED_ME

	if _cells_claimed_by_opponent.has(cell_position):
		return CELL_STATE_CLAIMED_OPPONENT

	if _board == null:
		return CELL_STATE_HIDDEN

	var cell := _board.get_cell(x, y)

	if cell == null or not cell.revealed:
		return CELL_STATE_HIDDEN

	match _usecase.classify_player(cell.revealed_by_player_id):
		"me":
			return CELL_STATE_REVEALED_ME
		"opponent":
			return CELL_STATE_REVEALED_OPPONENT
		_:
			return CELL_STATE_HIDDEN


func get_cell_letter(x: int, y: int) -> String:
	if _board == null:
		return ""

	var cell := _board.get_cell(x, y)

	if cell == null or not cell.revealed:
		return ""

	return cell.letter.to_upper()


func classify_word_owner(word: GameWord) -> String:
	if not word.found:
		return ""

	return _usecase.classify_player(word.found_by_player_id)


# Internal — trava otimista de ação
#
# Decisão de design deliberada: o MVP travava cliques por 1s de forma reativa
# à troca de turno. Aqui a trava é OTIMISTA — prende no instante em que o
# jogador local dispara uma ação e solta quando o turno passa, quando a ação
# é rejeitada, ou após um timeout de segurança de 3s (rede lenta). Cobre o
# mesmo objetivo (impedir clique duplo no round-trip do servidor) sem depender
# do nome cru de eventos WS, que não chega até esta camada.

func _lock_action() -> void:
	if _is_action_locked:
		return

	_is_action_locked = true
	action_lock_changed.emit(true)
	_schedule_action_unlock()


func _schedule_action_unlock() -> void:
	_action_lock_generation += 1
	var generation := _action_lock_generation

	await (Engine.get_main_loop() as SceneTree).create_timer(ACTION_LOCK_TIMEOUT_SECONDS).timeout

	if generation != _action_lock_generation or not _is_action_locked:
		return

	_unlock_action()


func _unlock_action() -> void:
	if not _is_action_locked:
		return

	_action_lock_generation += 1
	_is_action_locked = false
	action_lock_changed.emit(false)


# Internal — sinais do usecase

func _on_board_updated(board: GameBoard) -> void:
	_board = board
	board_changed.emit(board)


func _on_words_updated(words: Array) -> void:
	_words = words
	words_changed.emit(words)


func _on_my_inventory_updated(inventory: Array) -> void:
	_my_inventory = inventory
	my_inventory_changed.emit(inventory)


func _on_opponent_inventory_updated(inventory: Array) -> void:
	_opponent_inventory = inventory
	opponent_inventory_changed.emit(inventory)


func _on_power_granted(power: GamePower) -> void:
	power_granted.emit(power)


# Sem estado a atualizar nesta fase: a View pode reagir depois, se precisar.

func _on_my_cell_revealed() -> void:
	pass


func _on_word_found(cells: Array, found_by_player_id: String, is_me: bool) -> void:
	word_found_feedback.emit(cells, is_me)

	var claimed_cells := _cells_claimed_by_me if is_me else _cells_claimed_by_opponent

	for cell_variant in cells:
		if not cell_variant is Vector2i:
			continue

		var cell_position: Vector2i = cell_variant

		if not claimed_cells.has(cell_position):
			claimed_cells.append(cell_position)


func _on_trap_event(event_name: String, x: int, y: int) -> void:
	trap_event_feedback.emit(event_name, x, y)


func _on_connection_lost(message: String) -> void:
	_set_error(message)


func _on_turn_changed(current_turn_player_id: String, turn_ends_at: String, is_my_turn: bool) -> void:
	if current_turn_player_id != _last_turn_player_id and is_my_turn:
		_apply_turn_effect_decrement()

	_last_turn_player_id = current_turn_player_id
	_is_my_turn = is_my_turn
	turn_state_changed.emit(is_my_turn)

	if not is_my_turn:
		_unlock_action()

	_turn_ends_at = turn_ends_at
	_start_turn_timer_loop()


func _on_my_effect_event(event_name: String) -> void:
	match event_name:
		"PLAYER_FROZEN":
			_is_frozen = true
			_freeze_turns_left = FREEZE_TURNS_DEFAULT
		"PLAYER_UNFREEZE":
			_is_frozen = false
			_freeze_turns_left = 0
		"PLAYER_USE_IMMUNITY", "IMMUNITY_APPLIED":
			_is_immune = true
			_immunity_turns_left = IMMUNITY_TURNS_DEFAULT
		"IMMUNITY_REMOVED":
			_is_immune = false
			_immunity_turns_left = 0
		"TRAPS_DETECTED":
			_is_detecting_traps = true
		"DETECT_TRAPS_REMOVED":
			_is_detecting_traps = false
		"SPY_APPLIED":
			_is_spied = true
		"SPY_REMOVED":
			_is_spied = false
		# Pareamento BLIND/LANTERN inferido por tema (LANTERN compartilha escopo
		# GLOBAL não ofensivo com BLIND) — não confirmado no MVP.
		# TODO: confirmar pareamento BLIND/LANTERN contra backend real
		"PLAYER_BLINDED":
			_is_blinded = true
		"PLAYER_USE_LANTERN":
			_is_blinded = false
		_:
			AppLogger.debug("GameViewModel: efeito não mapeado: %s" % event_name)
			return

	effect_state_changed.emit()


func _apply_turn_effect_decrement() -> void:
	var changed := false

	if _is_frozen:
		_freeze_turns_left -= 1

		if _freeze_turns_left <= 0:
			_freeze_turns_left = 0
			_is_frozen = false

		changed = true

	if _is_immune:
		_immunity_turns_left -= 1

		if _immunity_turns_left <= 0:
			_immunity_turns_left = 0
			_is_immune = false

		changed = true

	if changed:
		effect_state_changed.emit()


func _on_game_over(is_winner: bool, reason: String) -> void:
	_show_game_over(is_winner, reason)


func _show_game_over(is_winner: bool, reason: String) -> void:
	var title := ""
	var subtitle := ""

	match [is_winner, reason]:
		[true, REASON_WORDS]:
			title = "🏆 VOCÊ VENCEU!"
			subtitle = "Parabéns! Você encontrou mais palavras."
		[false, REASON_WORDS]:
			title = "💀 VOCÊ PERDEU!"
			subtitle = "O oponente foi melhor dessa vez. Tente novamente!"
		[true, REASON_OPPONENT_LEFT]:
			title = "OPONENTE FUGIU"
			subtitle = "Você venceu! O oponente foi desconectado."
		[false, REASON_INACTIVITY]:
			title = "💤 DESCONECTADO"
			subtitle = "Você foi removido por inatividade."
		_:
			title = "🏁 FIM DE JOGO"
			subtitle = "O jogo terminou."

	game_ended.emit(is_winner, title, subtitle)


func _on_action_rejected(error_code: String, cell_x: int, cell_y: int) -> void:
	_unlock_action()

	if error_code == "stepped_on_trap":
		trap_animation_requested.emit(cell_x, cell_y)
	elif error_code == "player_are_immune" or error_code.contains("imune"):
		notification_requested.emit("Ataque bloqueado! O oponente está imune 🛡️")
	elif error_code == "player_not_in_game":
		_show_game_over(true, REASON_OPPONENT_LEFT)
	elif error_code == "the selected cell has already been revealed":
		# Clique redundante do próprio usuário em célula já revelada —
		# ignorado sem feedback de erro (a trava já foi liberada acima).
		pass
	else:
		notification_requested.emit("Ação inválida.")
		AppLogger.debug("GameViewModel: código de erro desconhecido: %s" % error_code)


# Internal — countdown do turno
#
# Um token de geração aborta o loop anterior quando um novo turn_changed chega,
# evitando múltiplas coroutines de timer empilhadas ao mesmo tempo.

func _start_turn_timer_loop() -> void:
	_turn_timer_generation += 1

	if _turn_ends_at.is_empty():
		return

	var generation := _turn_timer_generation
	var deadline := _parse_turn_deadline(_turn_ends_at)

	if deadline < 0:
		return

	_run_turn_timer_loop(generation, deadline)


func _parse_turn_deadline(datetime_string: String) -> float:
	# Time.get_unix_time_from_datetime_string não trata sufixos de timezone
	# ("Z") nem faz conversão de fuso — o "Z" precisa ser removido à mão. A
	# fração decimal (".000") é ignorada silenciosamente pela engine. Como o
	# backend envia UTC com "Z" e Time.get_unix_time_from_system() também é
	# UTC, a comparação direta dos timestamps é válida. Falha de parse retorna
	# 0 — tratado como deadline inválido (sentinela -1).
	var normalized := datetime_string.trim_suffix("Z")
	var unix_time := Time.get_unix_time_from_datetime_string(normalized)

	if unix_time <= 0:
		return -1.0

	return float(unix_time)


func _run_turn_timer_loop(generation: int, deadline: float) -> void:
	while generation == _turn_timer_generation:
		var remaining := deadline - Time.get_unix_time_from_system()

		if remaining <= 0.0:
			turn_timer_updated.emit(0.0)
			return

		turn_timer_updated.emit(remaining)
		await (Engine.get_main_loop() as SceneTree).create_timer(TURN_TIMER_TICK_SECONDS).timeout
