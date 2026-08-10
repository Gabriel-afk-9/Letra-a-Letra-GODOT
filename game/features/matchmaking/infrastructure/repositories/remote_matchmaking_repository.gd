extends MatchmakingRepository
class_name RemoteMatchmakingRepository


const MATCHMAKING_EVENT := "MATCHMAKING_GAME"
const STATUS_FOUND := "FOUNDED"
const DEFAULT_GAME_MODE := "INSANE"

var _websocket: WebSocketClient
var _current_user_provider: CurrentUserProvider


func _init(websocket: WebSocketClient, current_user_provider: CurrentUserProvider) -> void:
	_websocket = websocket
	_current_user_provider = current_user_provider

	_websocket.connected.connect(_on_connected)
	_websocket.connection_error.connect(_on_connection_error)
	_websocket.message_received.connect(_on_message_received)
	_websocket.disconnected.connect(_on_disconnected)



# Public API

func start_search() -> void:
	if _websocket.is_socket_connected():
		return

	searching.emit()
	_websocket.connect_socket()


func cancel_search() -> void:
	_websocket.disconnect_socket()
	search_cancelled.emit()



# Internal — ciclo de vida do socket

func _on_connected() -> void:
	AppLogger.info("Connected to matchmaking server.")
	_websocket.send({
		"type": MATCHMAKING_EVENT,
		"gameMode": DEFAULT_GAME_MODE
	})


func _on_disconnected() -> void:
	AppLogger.info("Disconnected from matchmaking server.")


func _on_connection_error(message: String) -> void:
	AppLogger.error(message)
	error.emit(message)



# Internal — mensagens recebidas

func _on_message_received(message: WebSocketMessage) -> void:
	match message.event:
		MATCHMAKING_EVENT:
			_handle_matchmaking(message)
		"ERROR":
			_handle_error(message)
		_:
			AppLogger.debug("Unhandled websocket event: %s" % message.event)


func _handle_matchmaking(message: WebSocketMessage) -> void:
	var status := message.get_string("status")

	if status.is_empty():
		error.emit("Missing matchmaking status.")
		return

	if status != STATUS_FOUND:
		return

	var players_variant = message.data.get("players", [])

	if not players_variant is Array:
		error.emit("Invalid matchmaking payload.")
		return

	var players: Array = players_variant
	var me := _current_user_provider.current_user()

	if me == null:
		error.emit("Authenticated user not found.")
		return

	var opponent: MatchmakingPlayer = _find_opponent(players, me.id)

	if opponent == null:
		error.emit("Opponent not found.")
		return

	var current_player := MatchmakingPlayer.new(me.id, me.nickname)
	var current_turn_player_id := str(message.data.get("currentTurnPlayerId", ""))

	match_found.emit(
		MatchmakingFoundEvent.new(
			message.get_string("gameId"),
			current_player,
			opponent,
			current_turn_player_id
		)
	)


func _handle_error(message: WebSocketMessage) -> void:
	var error_message := message.message

	if error_message.is_empty():
		error_message = "Unknown websocket error."

	AppLogger.error(error_message)
	error.emit(error_message)


func _find_opponent(players: Array, my_id: String) -> MatchmakingPlayer:
	for player_variant in players:
		if not player_variant is Dictionary:
			continue

		var player: Dictionary = player_variant
		var id: String = str(player.get("id", ""))

		if id == my_id:
			continue

		return MatchmakingPlayer.from_dictionary(player)

	return null
