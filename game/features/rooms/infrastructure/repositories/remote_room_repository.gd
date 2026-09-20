extends RoomRepository
class_name RemoteRoomRepository

const CREATE_TYPE := "CREATE_GAME"
const JOIN_TYPE := "JOIN_GAME"
const EVENT_GAME_CREATED := "GAME_CREATED"
const EVENT_PARTICIPANT_JOIN := "PARTICIPANT_JOIN"
const EVENT_ERROR := "ERROR"

var _http_client: HttpClient
var _websocket: WebSocketClient
var _create_pending: bool = false
var _pending_payload: Dictionary = {}
var _join_pending: bool = false
var _join_payload: Dictionary = {}


func _init(http_client: HttpClient, websocket_client: WebSocketClient = null) -> void:
	_http_client = http_client
	_websocket = websocket_client


func fetch_public_rooms(page: int, size: int) -> Dictionary:
	var response: HttpResponse = await _http_client.http_get(
		"/game/public?page=%d&size=%d" % [page, size]
	)
	if not response.success:
		return {"error": _message_or_default(response), "status_code": response.status_code}
	var result := RoomMapper.page_from_body(response.body)
	if result.is_empty():
		return {"error": "Resposta inválida do servidor.", "status_code": response.status_code}
	result["status_code"] = response.status_code
	return result


func search_rooms_by_name(room_name: String, page: int, size: int) -> Dictionary:
	var response: HttpResponse = await _http_client.http_get(
		"/game/active/room-name/%s?page=%d&size=%d" % [room_name.uri_encode(), page, size]
	)
	if not response.success:
		return {"error": _message_or_default(response), "status_code": response.status_code}
	var result := RoomMapper.page_from_body(response.body)
	if result.is_empty():
		return {"error": "Resposta inválida do servidor.", "status_code": response.status_code}
	result["status_code"] = response.status_code
	return result


func find_game_by_code(code: String) -> Dictionary:
	var response: HttpResponse = await _http_client.http_get(
		"/game/code/%s" % code.uri_encode()
	)
	if not response.success:
		return {"error": _message_or_default(response), "status_code": response.status_code}
	var result := RoomMapper.code_from_body(response.body)
	if result.is_empty():
		return {"error": "Resposta inválida do servidor.", "status_code": response.status_code}
	result["status_code"] = response.status_code
	return result


func _message_or_default(response: HttpResponse) -> String:
	if not response.error_message.is_empty():
		return response.error_message
	return "Falha de conexão. Tente novamente."


func create_room(room_name: String, allow_spectators: bool, private_game: bool) -> void:
	if _create_pending:
		return
	if _websocket == null:
		create_failed.emit("Falha de conexão. Tente novamente.")
		return
	_create_pending = true
	_pending_payload = {
		"type": CREATE_TYPE,
		"name": room_name,
		"settings": {
			"allowSpectators": allow_spectators,
			"privateGame": private_game
		}
	}
	_ensure_ws_subscription()
	_send_pending_or_connect()


func join_room(game_id: String) -> void:
	if _join_pending:
		return
	if _websocket == null:
		join_failed.emit("Falha de conexão. Tente novamente.")
		return
	_join_pending = true
	_join_payload = {
		"type": JOIN_TYPE,
		"gameId": game_id
	}
	_ensure_ws_subscription()
	_send_pending_or_connect()


func _send_pending_or_connect() -> void:
	if _websocket == null:
		return
	if _websocket.is_socket_connected():
		_send_create_pending()
		_send_join_pending()
	else:
		_websocket.connect_socket()


func _ensure_ws_subscription() -> void:
	if _websocket == null:
		return
	if not _websocket.message_received.is_connected(_on_ws_message):
		_websocket.message_received.connect(_on_ws_message)
	if not _websocket.disconnected.is_connected(_on_ws_disconnected):
		_websocket.disconnected.connect(_on_ws_disconnected)
	if not _websocket.connection_error.is_connected(_on_ws_connection_error):
		_websocket.connection_error.connect(_on_ws_connection_error)
	if not _websocket.connected.is_connected(_on_ws_connected):
		_websocket.connected.connect(_on_ws_connected)


func _release_ws_subscription() -> void:
	if _create_pending or _join_pending:
		return
	if _websocket == null:
		return
	if _websocket.message_received.is_connected(_on_ws_message):
		_websocket.message_received.disconnect(_on_ws_message)
	if _websocket.disconnected.is_connected(_on_ws_disconnected):
		_websocket.disconnected.disconnect(_on_ws_disconnected)
	if _websocket.connection_error.is_connected(_on_ws_connection_error):
		_websocket.connection_error.disconnect(_on_ws_connection_error)
	if _websocket.connected.is_connected(_on_ws_connected):
		_websocket.connected.disconnect(_on_ws_connected)


func _send_create_pending() -> void:
	if not _create_pending or _pending_payload.is_empty():
		return
	_websocket.send(_pending_payload)


func _send_join_pending() -> void:
	if not _join_pending or _join_payload.is_empty():
		return
	_websocket.send(_join_payload)


func _on_ws_connected() -> void:
	_send_create_pending()
	_send_join_pending()


func _on_ws_message(message: WebSocketMessage) -> void:
	if _create_pending:
		_handle_create_message(message)
	if _join_pending:
		_handle_join_message(message)


func _handle_create_message(message: WebSocketMessage) -> void:
	match message.event:
		EVENT_GAME_CREATED:
			var room := RoomMapper.from_dictionary(message.data)
			if room == null:
				_fail_create("Resposta inválida do servidor.")
			else:
				_succeed_create(room)
		EVENT_ERROR:
			if message.message.strip_edges().is_empty():
				_fail_create("Falha de conexão. Tente novamente.")
			else:
				_fail_create(message.message)
		_:
			pass


func _handle_join_message(message: WebSocketMessage) -> void:
	match message.event:
		EVENT_PARTICIPANT_JOIN:
			var room := RoomMapper.from_dictionary(message.data)
			if room == null:
				_fail_join("Resposta inválida do servidor.")
			else:
				_succeed_join(room)
		EVENT_ERROR:
			if message.message.strip_edges().is_empty():
				_fail_join("Falha de conexão. Tente novamente.")
			else:
				_fail_join(message.message)
		_:
			pass


func _on_ws_disconnected() -> void:
	if _create_pending:
		_fail_create("Conexão perdida. Tente novamente.")
	if _join_pending:
		_fail_join("Conexão perdida. Tente novamente.")


func _on_ws_connection_error(message: String) -> void:
	var text := message.strip_edges()
	if text.is_empty():
		text = "Conexão perdida. Tente novamente."
	if _create_pending:
		_fail_create(text)
	if _join_pending:
		_fail_join(text)


func _succeed_create(room: Room) -> void:
	_finish_create()
	room_created.emit(room)


func _fail_create(message: String) -> void:
	_finish_create()
	create_failed.emit(message)


func _finish_create() -> void:
	_create_pending = false
	_pending_payload = {}
	_release_ws_subscription()


func _succeed_join(room: Room) -> void:
	_finish_join()
	room_joined.emit(room)


func _fail_join(message: String) -> void:
	_finish_join()
	join_failed.emit(message)


func _finish_join() -> void:
	_join_pending = false
	_join_payload = {}
	_release_ws_subscription()
