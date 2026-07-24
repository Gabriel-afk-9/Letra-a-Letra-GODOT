extends Node

signal connected
signal disconnected
signal message_received(event_name: String, data: Dictionary)
signal error_occurred(message: String)

var socket := WebSocketPeer.new()
var _was_connected := false

func connect_to_server(url: String) -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		socket.close()
	socket.connect_to_url(url)
	
func send_action(type: String, extra_data: Dictionary = {}) -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var payload = { "type": type }
		payload.merge(extra_data)
		socket.send_text(JSON.stringify(payload))

func _process(_delta: float) -> void:
	socket.poll()
	var state = socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not _was_connected:
			_was_connected = true
			connected.emit()
			
		while socket.get_available_packet_count() > 0:
			var packet = socket.get_packet().get_string_from_utf8()
			_parse_message(packet)

	elif state == WebSocketPeer.STATE_CLOSED:
		if _was_connected:
			_was_connected = false
			disconnected.emit()

func _parse_message(text: String) -> void:
	var json = JSON.new()
	if json.parse(text) == OK:
		var response = json.data
	
		if response.has("event"):
			if response["event"] == "ERROR":
				error_occurred.emit(response.get("message", "Erro desconhecido no servidor"))
			else:
				message_received.emit(response["event"], response.get("data", {}))
