extends GameRepository
class_name RemoteGameRepository


const EVENT_PLAYER_ACTION_RESULT := "PLAYER_ACTION_RESULT"
const EVENT_TURN_EXPIRED := "TURN_EXPIRED"
const EVENT_GAME_OVER := "GAME_OVER"
const EVENT_PARTICIPANT_LEAVE := "PARTICIPANT_LEAVE"
const EVENT_PARTICIPANT_DISCONNECTED := "PARTICIPANT_DISCONNECTED"
const EVENT_PARTICIPANT_RECONNECTED := "PARTICIPANT_RECONNECTED"
const EVENT_REMOVED_BECAUSE_INACTIVITY := "REMOVED_BECAUSE_INACTIVITY"
const EVENT_POWER_DISCARDED := "POWER_DISCARDED"
const EVENT_ERROR := "ERROR"

const EXPIRED_TURN_FALLBACK_SECONDS := 45

const ACTION_PLAYER_ACTION := "PLAYER_ACTION"
const ACTION_REVEAL := "REVEAL"
const ACTION_DISCARD_POWER := "DISCARD_POWER"
const ACTION_LEFT_GAME := "LEFT_GAME"


var _websocket: WebSocketClient
var _current_user_provider: CurrentUserProvider
var _game_id: String = ""
var _leave_started: bool = false

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
	SessionStore.set_current_game_id(game_id)
	_persist_game_id(game_id)
	_flush_pending_state()

func _persist_game_id(game_id: String) -> void:
	var user := _current_user_provider.current_user()
	if user == null:
		return
	var path := "user://session_%s.cfg" % str(user.id)
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(path):
		cfg.load(path)
	cfg.set_value("session", "game_id", game_id)
	var user_dict := {"id": user.id, "email": user.email, "nickname": user.nickname}
	for k in user_dict:
		cfg.set_value("user", k, user_dict[k])
	var token := SessionStore.get_token()
	if not token.is_empty():
		cfg.set_value("session", "token", token)
	cfg.save(path)

func _load_persisted_game_id() -> String:
	var user := _current_user_provider.current_user()
	if user == null:
		return ""
	var path := "user://session_%s.cfg" % str(user.id)
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return ""
	return str(cfg.get_value("session", "game_id", ""))

func _clear_persisted_game_id() -> void:
	var user := _current_user_provider.current_user()
	if user == null:
		var dir := DirAccess.open("user://")
		if dir != null:
			dir.list_dir_begin()
			var f := dir.get_next()
			while f != "":
				if f.begins_with("session_") and f.ends_with(".cfg"):
					var c := ConfigFile.new()
					if c.load("user://%s" % f) == OK:
						c.set_value("session", "game_id", "")
						c.save("user://%s" % f)
				f = dir.get_next()
			dir.list_dir_end()
		return
	var path := "user://session_%s.cfg" % str(user.id)
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		cfg.set_value("session", "game_id", "")
		cfg.save(path)
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


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
	use_power_on_cell(power_id, power_type, x, y)


func use_power_on_cell(power_id: String, power_type: String, x: int, y: int) -> void:
	_send_action({
		"type": power_type,
		"actionId": power_id,
		"position": {
			"x": x,
			"y": y
		}
	})


func use_global_power(power_id: String, power_type: String, target_id: String) -> void:
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

	_leave_started = true

	var effective_game_id := _game_id
	if effective_game_id.is_empty():
		effective_game_id = SessionStore.get_current_game_id()
	if effective_game_id.is_empty():
		effective_game_id = _load_persisted_game_id()

	if effective_game_id.is_empty():
		AppLogger.debug("[GAME][%s] WS GHOST LEAVE without gameId - clearing local and disconnecting" % _current_user_id())
		_clear_game_state()
		return

	AppLogger.debug("[GAME][%s] WS OUT LEFT_GAME gameId=%s" % [_current_user_id(), effective_game_id])

	_websocket.send({
		"type": ACTION_LEFT_GAME,
		"gameId": effective_game_id
	})

	_clear_game_state()

func force_ghost_leave() -> void:
	if _leave_started:
		_leave_started = false
	_leave_started = true
	var ghost_id := _game_id
	if ghost_id.is_empty():
		ghost_id = SessionStore.get_current_game_id()
	if ghost_id.is_empty():
		ghost_id = _load_persisted_game_id()
		if not ghost_id.is_empty():
			AppLogger.debug("[GAME][%s] WS GHOST recovered gameId from file %s" % [_current_user_id(), ghost_id])
	if not ghost_id.is_empty():
		AppLogger.debug("[GAME][%s] WS GHOST force leave with gameId=%s" % [_current_user_id(), ghost_id])
		_websocket.send({
			"type": ACTION_LEFT_GAME,
			"gameId": ghost_id
		})
	else:
		AppLogger.debug("[GAME][%s] WS GHOST force leave without gameId" % _current_user_id())
	_websocket.send({
		"type": "EXIT_MATCHMAKING"
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



func _clear_game_state() -> void:
	_pending_board = null
	_pending_words = []
	_pending_players = []
	_pending_turn_player_id = ""
	_pending_turn_ends_at = ""
	_game_id = ""
	SessionStore.clear_current_game_id()
	_clear_persisted_game_id()
	_websocket.disconnect_socket()



func _on_connection_error(message: String) -> void:
	connection_lost.emit(message)


func _on_disconnected() -> void:
	connection_lost.emit("")



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
		EVENT_PARTICIPANT_RECONNECTED:
			AppLogger.debug("[GAME] participant reconnected - syncing state")
			pass
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

	if current_turn_player_id == "null" or current_turn_player_id == "<null>" or current_turn_player_id == "None":
		current_turn_player_id = ""

	if turn_ends_at == "null" or turn_ends_at == "<null>" or turn_ends_at == "None":
		turn_ends_at = ""

	if message.event == EVENT_POWER_DISCARDED and turn_ends_at.is_empty():
		return

	if message.event == EVENT_TURN_EXPIRED and turn_ends_at.is_empty() and not current_turn_player_id.is_empty():
		turn_ends_at = _synthesize_turn_ends_at(EXPIRED_TURN_FALLBACK_SECONDS)

	if current_turn_player_id.is_empty() and turn_ends_at.is_empty():
		return

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


func _synthesize_turn_ends_at(seconds_ahead: int) -> String:
	var deadline_unix := Time.get_unix_time_from_system() + seconds_ahead
	var datetime_string := Time.get_datetime_string_from_unix_time(deadline_unix, true)

	return datetime_string.trim_suffix("Z") + "Z"


func _first_string(message: WebSocketMessage, key: String) -> String:
	if message.has(key):
		var raw_value = message.raw.get(key)

		if raw_value == null:
			return ""

		return str(raw_value)

	var data_value = message.data.get(key, "")

	if data_value == null:
		return ""

	return str(data_value)
