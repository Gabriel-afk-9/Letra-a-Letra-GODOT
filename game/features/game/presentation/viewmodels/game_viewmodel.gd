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
const CELL_STATE_SPY_ME := "SPY_ME"
const CELL_STATE_BLINDED := "BLINDED"
const CELL_STATE_TRAP_ME := "TRAP_ME"
const CELL_STATE_TRAP_OPPONENT := "TRAP_OPPONENT"
const CELL_STATE_BLOCK_ME := "BLOCK_ME"
const CELL_STATE_BLOCK_OPPONENT := "BLOCK_OPPONENT"

const FREEZE_TURNS_DEFAULT := 3
const IMMUNITY_TURNS_DEFAULT := 5
const BLIND_TURNS_DEFAULT := 6
const ACTION_LOCK_TIMEOUT_SECONDS := 1.2
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
var _blind_turns_left: int = 0
var _is_detecting_traps: bool = false
var _is_spied: bool = false

var _armed_power_id: String = ""
var _armed_power_type: String = ""

var _cells_claimed_by_me: Array[Vector2i] = []
var _cells_claimed_by_opponent: Array[Vector2i] = []
# S2 SPY: célula espiada visível só para o dono (oponente segue HIDDEN)
var _spied_cell := Vector2i(-1, -1)
var _has_spied := false


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
	_usecase.spy_position_changed.connect(_on_spy_position_changed)
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

	# Sprint 2: backend exige sua vez para tudo (REVEAL e CELL) — fora da vez zero WS OUT
	if not _is_my_turn:
		return

	# Sprint 2: congelado bloqueia REVEAL e todo CELL (nenhum CELL tem can_use_while_frozen)
	if _is_frozen:
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
	# Legado (testes + compat): disparo imediato para GLOBAL, armar para CELL.
	# Gates alinhados com on_power_clicked/confirm (Sprint 2/4) para não furar turno/frozen.
	if not _is_my_turn:
		return

	if _is_frozen and not GamePowerCatalog.can_use_while_frozen(power_type):
		return

	if _is_action_locked and not GamePowerCatalog.can_use_while_frozen(power_type):
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

	# Bypass catalog: UNFREEZE/IMMUNITY podem armar mesmo com action_lock
	if _is_action_locked and not GamePowerCatalog.can_use_while_frozen(power.type):
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

	# Sprint 2: fora da vez mantém armado para tentar de novo no seu turno
	if not _is_my_turn:
		return

	if _is_frozen and not GamePowerCatalog.can_use_while_frozen(_armed_power_type):
		clear_selected_power()
		return

	# Sprint 2: trava otimista bloqueia GLOBAL comum, mas UNFREEZE/IMMUNITY furam lock
	if _is_action_locked and not GamePowerCatalog.can_use_while_frozen(_armed_power_type):
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


# Sprint 4: inventário cheio (5/5) trava drop do servidor — expõe helper para
# a View oferecer descarte sem mexer no fluxo de armar/disparar.
func is_inventory_full() -> bool:
	return _count_my_powers() >= GamePlayerState.INVENTORY_SIZE


func discard_armed_power() -> void:
	if _armed_power_id.is_empty():
		return

	_usecase.discard_power(_armed_power_id)
	clear_selected_power()


func _count_my_powers() -> int:
	var total := 0

	for p in _my_inventory:
		if p is GamePower:
			total += 1

	return total


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

	# S3 BLIND: vítima vê tudo preto (CLAIMED já resolvidas continuam visíveis)
	if _is_blinded:
		return CELL_STATE_BLINDED

	if _board == null:
		if _has_spied and cell_position == _spied_cell:
			return CELL_STATE_SPY_ME

		return CELL_STATE_HIDDEN

	var cell := _board.get_cell(x, y)

	if cell == null or not cell.revealed:
		# S5 TRAP/BLOCK: só em célula não revelada. Dono sempre vê a sua trap
		# (azul); trap do oponente só aparece com DETECT ativo (laranja);
		# block mostra a barra para os dois (3 REVEALs desbloqueiam).
		var effect_type := cell.effect_type.to_upper() if cell != null else ""
		var effect_owner := _usecase.classify_player(cell.effect_owner_id) if cell != null else ""

		if effect_type.contains("BLOCK"):
			if effect_owner == "me":
				return CELL_STATE_BLOCK_ME

			return CELL_STATE_BLOCK_OPPONENT

		if effect_type.contains("TRAP"):
			if effect_owner == "me":
				return CELL_STATE_TRAP_ME

			if effect_owner == "opponent" and _is_detecting_traps:
				return CELL_STATE_TRAP_OPPONENT

		if _has_spied and cell_position == _spied_cell:
			return CELL_STATE_SPY_ME

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

	if cell == null:
		return ""

	# S2 SPY: dono vê a letra mesmo sem reveal (se o backend mandar no sync)
	if get_cell_visual_state(x, y) == CELL_STATE_SPY_ME:
		return cell.letter.to_upper() if not cell.letter.is_empty() else ""

	# S3 BLIND: esconde todas as letras da vítima
	if _is_blinded:
		return ""

	if not cell.revealed:
		return ""

	return cell.letter.to_upper()


func get_cell_block_filled(x: int, y: int) -> int:
	# S5 BLOCK: segmentos preenchidos 0-3 = 3 - remainingClicks. Sem dado do
	# backend (0), assume recém-colocada (0 preenchidos).
	if _board == null:
		return 0

	var cell := _board.get_cell(x, y)

	if cell == null or not cell.effect_type.to_upper().contains("BLOCK"):
		return 0

	if cell.remaining_clicks <= 0:
		return 0

	return clampi(3 - cell.remaining_clicks, 0, 3)


func get_spied_cell() -> Vector2i:
	return _spied_cell


func has_spied_cell() -> bool:
	return _has_spied


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
	var claimed_cells := _cells_claimed_by_me if is_me else _cells_claimed_by_opponent

	for cell_variant in cells:
		if not cell_variant is Vector2i:
			continue

		var cell_position: Vector2i = cell_variant

		if not claimed_cells.has(cell_position):
			claimed_cells.append(cell_position)

	word_found_feedback.emit(cells, is_me)

	# Garante repintura no mesmo frame após o append: o board já foi emitido
	# antes do WORD_FOUNDED no mesmo envelope (remote reparte board antes do
	# evento), então sem este reemit o board_changed seguinte só viria no
	# próximo PLAYER_ACTION_RESULT do oponente.
	if _board != null:
		board_changed.emit(_board)


func _on_trap_event(event_name: String, x: int, y: int) -> void:
	trap_event_feedback.emit(event_name, x, y)


func _on_connection_lost(message: String) -> void:
	_set_error(message)


func _on_turn_changed(current_turn_player_id: String, turn_ends_at: String, is_my_turn: bool) -> void:
	if current_turn_player_id != _last_turn_player_id and is_my_turn:
		_apply_turn_effect_decrement()

	_last_turn_player_id = current_turn_player_id
	_is_my_turn = is_my_turn
	_turn_ends_at = turn_ends_at

	# Aquece a etiqueta antes da tela redesenhar na troca de dono: emite o
	# restante já no prazo novo para nunca piscar o 0s do turno anterior.
	if not turn_ends_at.is_empty():
		var warm_deadline := _parse_turn_deadline(turn_ends_at)

		if warm_deadline > 0.0:
			turn_timer_updated.emit(maxf(0.0, warm_deadline - Time.get_unix_time_from_system()))

	turn_state_changed.emit(is_my_turn)

	if not is_my_turn:
		_unlock_action()

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
		"SPY_APPLIED", "PLAYER_SPIED":
			_is_spied = true
		"SPY_REMOVED":
			_is_spied = false
		# Pareamento BLIND/LANTERN inferido por tema (LANTERN compartilha escopo
		# GLOBAL não ofensivo com BLIND) — não confirmado no MVP.
		# TODO: confirmar pareamento BLIND/LANTERN contra backend real
		"PLAYER_BLINDED":
			_is_blinded = true
			_blind_turns_left = BLIND_TURNS_DEFAULT
		"PLAYER_USE_LANTERN":
			_is_blinded = false
			_blind_turns_left = 0
		_:
			AppLogger.debug("GameViewModel: efeito não mapeado: %s" % event_name)
			return

	effect_state_changed.emit()


func _on_spy_position_changed(pos: Vector2i, active: bool) -> void:
	if active:
		_spied_cell = pos
		_has_spied = true
	else:
		_spied_cell = Vector2i(-1, -1)
		_has_spied = false

	effect_state_changed.emit()

	if _board != null:
		board_changed.emit(_board)


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

	if _is_blinded:
		_blind_turns_left -= 1

		if _blind_turns_left <= 0:
			_blind_turns_left = 0
			_is_blinded = false

		changed = true

	if changed:
		effect_state_changed.emit()


func _on_game_over(is_winner: bool, reason: String) -> void:
	# GAME_OVER por inatividade manda vencedor via GAME_OVER (REASON_WORDS)
	# e perdedor via REMOVED_BECAUSE_INACTIVITY. Sem palavra encontrada e
	# jogo encerrado cedo, "Parabéns! Você encontrou mais palavras" é falso —
	# trata como W.O. (oponente removido).
	if is_winner and reason == REASON_WORDS and not _has_any_word_found():
		reason = REASON_OPPONENT_LEFT

	_show_game_over(is_winner, reason)


func _has_any_word_found() -> bool:
	for word_variant in _words:
		if word_variant is GameWord and (word_variant as GameWord).found:
			return true

	return false


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

	var code := error_code.strip_edges().to_lower()

	if code == "stepped_on_trap" or code.contains("trap"):
		trap_animation_requested.emit(cell_x, cell_y)
	elif code == "player_are_immune" or code.contains("imune") or code.contains("immune"):
		notification_requested.emit("Ataque bloqueado! O oponente está imune 🛡️")
	elif code == "player_not_in_game" or code.contains("not currently in a game"):
		_show_game_over(true, REASON_OPPONENT_LEFT)
	elif code == "the selected cell has already been revealed" or code.contains("already been revealed") or code.contains("already_revealed"):
		# Clique redundante do próprio usuário em célula já revelada —
		# ignorado sem feedback de erro (a trava já foi liberada acima).
		pass
	elif code.contains("frozen") or code.contains("frozen_cannot_act"):
		notification_requested.emit("Congelado! Use DESCONGELAR ❄️")
	elif code.contains("not_your_turn") or code.contains("not your turn"):
		notification_requested.emit("Aguarde sua vez ⏳")
	elif code.contains("invalid_player_action") or code.contains("requested player action is invalid"):
		notification_requested.emit("Ação inválida.")
	else:
		notification_requested.emit("Ação inválida.")
		AppLogger.debug("GameViewModel: código de erro desconhecido: %s" % error_code)


# Internal — countdown do turno
#
# Um token de geração aborta o loop anterior quando um novo turn_changed chega,
# evitando múltiplas coroutines de timer empilhadas ao mesmo tempo.

func _start_turn_timer_loop() -> void:
	# DISCARD_POWER não vira o turno (turnEndsAt null/ignorado): deadline
	# inválido retorna cedo SEM bumpar a geração, para não matar o loop
	# do timer atual — descartar só limpa o slot e mantém a vez.
	if _turn_ends_at.is_empty():
		return

	var deadline := _parse_turn_deadline(_turn_ends_at)

	if deadline < 0:
		return

	_turn_timer_generation += 1
	_run_turn_timer_loop(_turn_timer_generation, deadline)


func parse_turn_deadline(datetime_string: String) -> float:
	# Wrapper público para testes Fase 2 — delega à lógica privada
	return _parse_turn_deadline(datetime_string)


func _parse_turn_deadline(datetime_string: String) -> float:
	# Time.get_unix_time_from_datetime_string não trata sufixos de timezone
	# ("Z") nem faz conversão de fuso — o "Z" precisa ser removido à mão. A
	# fração decimal (".000") é ignorada silenciosamente pela engine. Como o
	# backend envia UTC com "Z" e Time.get_unix_time_from_system() também é
	# UTC, a comparação direta dos timestamps é válida. Falha de parse retorna
	# 0 — tratado como deadline inválido (sentinela -1). Sentinelas de null
	# serializado ("null"/"<null>"/"None" — ex: turnEndsAt após DISCARD_POWER)
	# também são deadline inválido, sem tocar no relógio atual. O backend Java
	# (Instant.toString) manda fração longa (ex: ".832158445") que a engine não
	# aceita — descarta a fração e converte só até os segundos.
	if datetime_string == "null" or datetime_string == "<null>" or datetime_string == "None":
		return -1.0

	var normalized := datetime_string.trim_suffix("Z")
	var dot := normalized.find(".")

	if dot != -1:
		normalized = normalized.substr(0, dot)

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
