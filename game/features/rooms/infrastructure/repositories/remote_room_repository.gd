extends RoomRepository
class_name RemoteRoomRepository

const CREATE_TYPE := "CREATE_GAME"
const EVENT_GAME_CREATED := "GAME_CREATED"
const EVENT_ERROR := "ERROR"

var _http_client: HttpClient
var _websocket: WebSocketClient
var _create_pending: bool = false
var _pending_payload: Dictionary = {}


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
	_websocket.message_received.connect(_on_ws_message)
	_websocket.disconnected.connect(_on_ws_disconnected)
	_websocket.connection_error.connect(_on_ws_connection_error)
	_websocket.connected.connect(_on_ws_connected)
	if _websocket.is_socket_connected():
		_send_pending()
	else:
		_websocket.connect_socket()


func _send_pending() -> void:
	if not _create_pending or _pending_payload.is_empty():
		return
	_websocket.send(_pending_payload)


func _on_ws_connected() -> void:
	_send_pending()


func _on_ws_message(message: WebSocketMessage) -> void:
	if not _create_pending:
		return
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


func _on_ws_disconnected() -> void:
	if not _create_pending:
		return
	_fail_create("Conexão perdida. Tente novamente.")


func _on_ws_connection_error(message: String) -> void:
	if not _create_pending:
		return
	if message.strip_edges().is_empty():
		_fail_create("Conexão perdida. Tente novamente.")
	else:
		_fail_create(message)


func _succeed_create(room: Room) -> void:
	_finish_create()
	room_created.emit(room)


func _fail_create(message: String) -> void:
	_finish_create()
	create_failed.emit(message)


func _finish_create() -> void:
	_create_pending = false
	_pending_payload = {}
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
