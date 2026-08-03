extends MatchmakingRepository

class_name RemoteMatchmakingRepository


const MATCHMAKING_EVENT := "MATCHMAKING_GAME"


var _websocket: WebSocketClient
var _current_user_provider: CurrentUserProvider


func _init(
	websocket: WebSocketClient,
	current_user_provider: CurrentUserProvider
) -> void:

	_websocket = websocket
	_current_user_provider = current_user_provider

	_websocket.connected.connect(_on_connected)
	_websocket.connection_error.connect(_on_connection_error)
	_websocket.message_received.connect(_on_message_received)
	_websocket.disconnected.connect(_on_disconnected)


func start_search() -> void:

	searching.emit()

	_websocket.connect_socket()


func cancel_search() -> void:

	_websocket.disconnect_socket()

	search_cancelled.emit()



func _on_connected() -> void:

	AppLogger.info("Connected to matchmaking server.")

	_websocket.send({
		"type": MATCHMAKING_EVENT,
		"gameMode": "INSANE"
	})


func _on_disconnected() -> void:

	AppLogger.info("Disconnected from matchmaking server.")


func _on_connection_error(
	message: String
) -> void:

	AppLogger.error(message)

	error.emit(message)


func _on_message_received(
	message: WebSocketMessage
) -> void:

	match message.event:

		MATCHMAKING_EVENT:
			_handle_matchmaking(message)

		"ERROR":
			_handle_error(message)

		_:
			AppLogger.debug(
				"Unhandled websocket event: %s" % message.event
			)

func _handle_matchmaking(
	message: WebSocketMessage
) -> void:

	var status: String = str(
		message.data.get("status", "")
	)

	if status != "FOUNDED":
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

	var opponent: MatchmakingPlayer = null

	for player_variant in players:

		if not player_variant is Dictionary:
			continue

		var player: Dictionary = player_variant

		var id: String = str(player.get("id", ""))

		if id == me.id:
			continue

		opponent = MatchmakingPlayer.new(
			id,
			str(player.get("nickname", "Opponent"))
		)

		break

	if opponent == null:

		error.emit("Opponent not found.")

		return

	var current_player := MatchmakingPlayer.new(
		me.id,
		me.nickname
	)

	match_found.emit(
		MatchmakingFoundEvent.new(
			str(message.data.get("tokenGameId", "")),
			current_player,
			opponent
		)
	)


func _handle_error(
	message: WebSocketMessage
) -> void:

	var error_message := message.message

	if error_message.is_empty():
		error_message = "Unknown websocket error."

	AppLogger.error(error_message)

	error.emit(error_message)
