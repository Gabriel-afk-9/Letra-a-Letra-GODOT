extends Node
class_name WebSocketClient


# Log bruto de toda mensagem WS recebida (aditivo, abaixo dos logs
# seletivos). Deixe false para silenciar o terminal.
const DEBUG_RAW_WS := true

signal connected
signal disconnected
signal connection_error(message: String)
signal message_received(message: WebSocketMessage)

var _socket := WebSocketPeer.new()
var _auth_provider: AuthProvider
var _is_connecting: bool = false


func _init(auth_provider: AuthProvider) -> void:
	_auth_provider = auth_provider


func _process(_delta: float) -> void:
	if _socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		_socket.poll()

	match _socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			_handle_open_state()
		WebSocketPeer.STATE_CLOSED:
			_handle_closed_state()



# Public API

func connect_socket() -> void:
	disconnect_socket()

	var token := _auth_provider.get_token()

	if token.is_empty():
		AppLogger.error("Missing authentication token.")
		connection_error.emit("Authentication required.")
		return

	var url := "%s?token=%s" % [GlobalEnvironment.WS_BASE_URL, token]

	AppLogger.info("Connecting websocket...")
	var error := _socket.connect_to_url(url)

	if error != OK:
		AppLogger.error("Failed to connect websocket.")
		connection_error.emit("Connection failed.")
		return

	_is_connecting = true


func disconnect_socket() -> void:
	_is_connecting = false

	if _socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		_socket.close()
		AppLogger.info("WebSocket disconnected.")


func reconnect() -> void:
	disconnect_socket()
	connect_socket()


func is_socket_connected() -> bool:
	return _socket.get_ready_state() == WebSocketPeer.STATE_OPEN


func send(payload: Dictionary) -> void:
	if not is_socket_connected():
		AppLogger.error("WebSocket not connected.")
		return

	var json := JsonSerializer.encode(payload)
	var error := _socket.send_text(json)

	if error != OK:
		AppLogger.error("Failed to send websocket message.")
	else:
		AppLogger.debug("WS OUT -> " + json)



# Internal — estado da conexão

func _handle_open_state() -> void:
	if _is_connecting:
		_is_connecting = false
		AppLogger.info("WebSocket connected successfully.")
		connected.emit()

	while _socket.get_available_packet_count() > 0:
		_process_packet()


func _handle_closed_state() -> void:
	if _is_connecting:
		_is_connecting = false
		AppLogger.error("WebSocket connection closed or failed.")
		disconnected.emit()



# Internal — pacotes recebidos

func _process_packet() -> void:
	var text := _socket.get_packet().get_string_from_utf8()

	if DEBUG_RAW_WS:
		AppLogger.debug("WS IN -> " + text)

	var decoded: Variant = JsonSerializer.decode(text)

	if not decoded is Dictionary:
		AppLogger.error("Invalid websocket JSON.")
		connection_error.emit("Invalid websocket message.")
		return

	var body: Dictionary = decoded

	if body.is_empty():
		AppLogger.error("Empty websocket payload.")
		connection_error.emit("Invalid websocket message.")
		return

	var message := WebSocketMessage.from_dictionary(body)

	if not message.event.is_empty():
		AppLogger.debug("WS EVENT -> " + message.event)

	message_received.emit(message)
