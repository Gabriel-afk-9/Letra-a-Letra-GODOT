extends GameRepository
class_name RemoteGameRepository


const EVENT_PLAYER_ACTION_RESULT := "PLAYER_ACTION_RESULT"
const EVENT_TURN_EXPIRED := "TURN_EXPIRED"
const EVENT_GAME_OVER := "GAME_OVER"
const EVENT_PARTICIPANT_LEAVE := "PARTICIPANT_LEAVE"
const EVENT_PARTICIPANT_DISCONNECTED := "PARTICIPANT_DISCONNECTED"
const EVENT_REMOVED_BECAUSE_INACTIVITY := "REMOVED_BECAUSE_INACTIVITY"
const EVENT_POWER_DISCARDED := "POWER_DISCARDED"
const EVENT_ERROR := "ERROR"

# Turno provisório quando o backend vira a vez sem mandar deadline
# (TURN_EXPIRED não traz turnEndsAt): agora + 45s — alinha com a base
# 45 + 2*events do GameState/DelayQueue do backend. O próximo
# PLAYER_ACTION_RESULT corrige com o turnEndsAt real.
const EXPIRED_TURN_FALLBACK_SECONDS := 45

const ACTION_PLAYER_ACTION := "PLAYER_ACTION"
const ACTION_REVEAL := "REVEAL"
const ACTION_DISCARD_POWER := "DISCARD_POWER"
const ACTION_LEFT_GAME := "LEFT_GAME"


var _websocket: WebSocketClient
var _current_user_provider: CurrentUserProvider
var _game_id: String = ""
var _leave_started: bool = false

# Estado inicial da partida. O backend envia o snapshot (board, palavras,
# players com inventário e turno) no momento do matchmaking — ANTES de o
# game_id ser setado pelo start(). Como _handle_turn_update/_handle_state_sync
# descartavam mensagens com game_id vazio, o estado inicial era perdido e a UI
# só "acordava" após o primeiro clique. Guardamos aqui o último snapshot e o
# reemitimos no start(), reaproveitando exatamente os mesmos sinais.
var _pending_board: GameBoard = null
var _pending_words: Array = []
var _pending_players: Array = []
var _pending_turn_player_id: String = ""
var _pending_turn_ends_at: String = ""


func _init(websocket_client: WebSocketClient, current_user_provider: CurrentUserProvider) -> void:
	_websocket = websocket_client
	_current_user_provider = current_user_provider

	_websocket.message_received.connect(_on_message_received)
	_websocket.connection_error.connect(_on_connection_error)
	_websocket.disconnected.connect(_on_disconnected)



func start(game_id: String) -> void:
	_game_id = game_id
	_leave_started = false
	_flush_pending_state()


func _flush_pending_state() -> void:
	if _pending_board != null:
		board_updated.emit(_pending_board)

	if not _pending_words.is_empty():
		words_updated.emit(_pending_words)

	if not _pending_players.is_empty():
		players_updated.emit(_pending_players)

	if not _pending_turn_player_id.is_empty() or not _pending_turn_ends_at.is_empty():
		turn_updated.emit(_pending_turn_player_id, _pending_turn_ends_at)

	_pending_board = null
	_pending_words = []
	_pending_players = []
	_pending_turn_player_id = ""
	_pending_turn_ends_at = ""


func reveal_cell(x: int, y: int) -> void:
	_send_action({
		"type": ACTION_REVEAL,
		"position": {
			"x": x,
			"y": y
		}
	})


func use_cell_power(power_id: String, power_type: String, x: int, y: int) -> void:
	# Sprint 4: legado — delega para o caminho único CELL
	use_power_on_cell(power_id, power_type, x, y)


func use_power_on_cell(power_id: String, power_type: String, x: int, y: int) -> void:
	# CELL (BLOCK/UNBLOCK/TRAP/SPY): actionId + position, sem targetId
	_send_action({
		"type": power_type,
		"actionId": power_id,
		"position": {
			"x": x,
			"y": y
		}
	})


func use_global_power(power_id: String, power_type: String, target_id: String) -> void:
	# Ofensivos (FREEZE/BLIND) exigem targetId do oponente.
	# Defesa: se tipo não ofensivo cair aqui por rota legada, omite targetId
	# para não gerar 500 no backend (SELF só aceita actionId).
	if GamePowerCatalog.is_offensive(power_type):
		_send_action({
			"type": power_type,
			"actionId": power_id,
			"targetId": target_id
		})
	else:
		_send_action({
			"type": power_type,
			"actionId": power_id
		})


func use_self_power(power_id: String, power_type: String) -> void:
	# SELF (UNFREEZE/LANTERN/IMMUNITY/DETECT_TRAPS): só actionId, sem targetId nem position
	_send_action({
		"type": power_type,
		"actionId": power_id
	})


func discard_power(power_id: String) -> void:
	if not _can_send():
		return

	_websocket.send({
		"type": ACTION_DISCARD_POWER,
		"gameId": _game_id,
		"powerId": power_id
	})


func leave_game() -> void:
	if _leave_started:
		return

	if not _can_send():
		return

	_leave_started = true

	AppLogger.debug("[GAME][%s] WS OUT LEFT_GAME gameId=%s" % [_current_user_id(), _game_id])

	_websocket.send({
		"type": ACTION_LEFT_GAME,
		"gameId": _game_id
	})

	_clear_game_state()


func _send_action(action: Dictionary) -> void:
	if not _can_send():
		return

	var raw_position = action.get("position")
	var cell_x := -1
	var cell_y := -1

	if raw_position is Dictionary:
		cell_x = int(raw_position.get("x", -1))
		cell_y = int(raw_position.get("y", -1))

	AppLogger.debug("[GAME][%s] WS OUT PLAYER_ACTION type=%s x=%d y=%d" % [_current_user_id(), action.get("type", ""), cell_x, cell_y])

	_websocket.send({
		"type": ACTION_PLAYER_ACTION,
		"gameId": _game_id,
		"action": action
	})


func _current_user_id() -> String:
	var user = _current_user_provider.current_user()

	if user == null:
		return "?"

	return str(user.id)


func _can_send() -> bool:
	if _game_id.is_empty():
		AppLogger.error("RemoteGameRepository: no active game, cannot send message.")
		return false

	return true


# Limpa exclusivamente o estado da partida que acabou de terminar (game_id e
# snapshot pendente). Chamado ao sair e quando eventos terminais chegam do
# backend. A trava de saída (_leave_started) NÃO é resetada aqui: ela só é
# liberada no start() da próxima partida, garantindo que LEFT_GAME nunca seja
# reenviado para a mesma partida já encerrada.

func _clear_game_state() -> void:
	_pending_board = null
	_pending_words = []
	_pending_players = []
	_pending_turn_player_id = ""
	_pending_turn_ends_at = ""
	_game_id = ""
	_websocket.disconnect_socket()


# Internal — ciclo de vida do socket

func _on_connection_error(message: String) -> void:
	connection_lost.emit(message)


func _on_disconnected() -> void:
	connection_lost.emit("")


# Internal — mensagens recebidas

func _on_message_received(message: WebSocketMessage) -> void:
	AppLogger.debug("[GAME][%s] received event=%s" % [_current_user_id(), message.event])

	_handle_turn_update(message)
	_handle_state_sync(message)
	_handle_internal_events(message)

	match message.event:
		EVENT_GAME_OVER:
			_handle_game_over(message)
			_clear_game_state()
		EVENT_PARTICIPANT_LEAVE, EVENT_PARTICIPANT_DISCONNECTED:
			opponent_disconnected.emit()
			_clear_game_state()
		EVENT_REMOVED_BECAUSE_INACTIVITY:
			removed_for_inactivity.emit()
			_clear_game_state()
		EVENT_ERROR:
			_handle_error(message)
		EVENT_PLAYER_ACTION_RESULT, EVENT_TURN_EXPIRED: # <--- ADICIONE O EVENTO AQUI
			pass
		_:
			AppLogger.debug("Unhandled websocket event: %s" % message.event)


func _handle_turn_update(message: WebSocketMessage) -> void:
	var current_turn_player_id := _first_string(message, "currentTurnPlayerId")
	var turn_ends_at := _first_string(message, "turnEndsAt")

	# DISCARD_POWER responde sem virar o turno (turnEndsAt null): ignorar
	# sentinelas para não emitir turn_updated inválido e não mexer no relógio.
	if current_turn_player_id == "null" or current_turn_player_id == "<null>" or current_turn_player_id == "None":
		current_turn_player_id = ""

	if turn_ends_at == "null" or turn_ends_at == "<null>" or turn_ends_at == "None":
		turn_ends_at = ""

	# POWER_DISCARDED só atualiza players/board (via _handle_state_sync) —
	# nunca vira o turno. Sem deadline, não emite turn_updated.
	if message.event == EVENT_POWER_DISCARDED and turn_ends_at.is_empty():
		return

	# TURN_EXPIRED vira a vez sem mandar deadline: sintetiza agora + 15s para
	# o relógio reiniciar. O próximo PLAYER_ACTION_RESULT corrige com o real.
	if message.event == EVENT_TURN_EXPIRED and turn_ends_at.is_empty() and not current_turn_player_id.is_empty():
		turn_ends_at = _synthesize_turn_ends_at(EXPIRED_TURN_FALLBACK_SECONDS)

	if current_turn_player_id.is_empty() and turn_ends_at.is_empty():
		return

	# Snapshot recebido antes do start() (ex: durante o matchmaking) — guarda
	# para reemitir no _flush_pending_state() em vez de descartar.
	if _game_id.is_empty():
		_pending_turn_player_id = current_turn_player_id
		_pending_turn_ends_at = turn_ends_at
		return

	turn_updated.emit(current_turn_player_id, turn_ends_at)


func _handle_state_sync(message: WebSocketMessage) -> void:
	if message.data.has("board"):
		var raw_board = message.data.get("board")

		if raw_board is Array:
			var board := GameBoardMapper.to_domain(raw_board)

			if _game_id.is_empty():
				_pending_board = board
			else:
				board_updated.emit(board)

	if message.data.has("words"):
		var raw_words = message.data.get("words")

		if raw_words is Array:
			var parsed_words: Array = []

			for raw_word in raw_words:
				if raw_word is Dictionary:
					parsed_words.append(GameWordMapper.to_domain(raw_word))

			if _game_id.is_empty():
				_pending_words = parsed_words
			else:
				words_updated.emit(parsed_words)

	if message.data.has("players"):
		var raw_players = message.data.get("players")

		if raw_players is Array:
			var parsed_players: Array = []

			for raw_player in raw_players:
				if raw_player is Dictionary:
					parsed_players.append(GamePlayerStateMapper.to_domain(raw_player))

			if _game_id.is_empty():
				_pending_players = parsed_players
			else:
				players_updated.emit(parsed_players)


func _handle_internal_events(message: WebSocketMessage) -> void:
	for raw_event in message.events:
		if not raw_event is Dictionary:
			continue

		var event_dict: Dictionary = raw_event

		internal_event_received.emit(
			GameInternalEventMapper.to_domain(event_dict)
		)


func _handle_game_over(message: WebSocketMessage) -> void:
	var raw_winner = message.data.get("winner")

	if not raw_winner is Dictionary:
		return

	var winner: Dictionary = raw_winner

	var raw_winner_id = winner.get("id")

	if raw_winner_id == null:
		return

	game_over.emit(str(raw_winner_id))


func _handle_error(message: WebSocketMessage) -> void:
	var error_code := message.message

	var cell_x := -1
	var cell_y := -1

	var raw_x = message.data.get("x")
	var raw_y = message.data.get("y")

	if raw_x is int or raw_x is float:
		cell_x = int(raw_x)

	if raw_y is int or raw_y is float:
		cell_y = int(raw_y)

	error.emit(error_code, cell_x, cell_y)


# Deadline provisório em ISO-8601 UTC com "Z" (mesmo formato do backend),
# para o ViewModel reiniciar o countdown sem esperar a próxima jogada.
func _synthesize_turn_ends_at(seconds_ahead: int) -> String:
	var deadline_unix := Time.get_unix_time_from_system() + seconds_ahead
	var datetime_string := Time.get_datetime_string_from_unix_time(deadline_unix, true)

	return datetime_string.trim_suffix("Z") + "Z"


func _first_string(message: WebSocketMessage, key: String) -> String:
	# Backend serializa null (ex: turnEndsAt após DISCARD_POWER): str(null)
	# geraria "null"/"<null>" não-vazio — filtrar para "" em vez disso.
	if message.has(key):
		var raw_value = message.raw.get(key)

		if raw_value == null:
			return ""

		return str(raw_value)

	var data_value = message.data.get(key, "")

	if data_value == null:
		return ""

	return str(data_value)
