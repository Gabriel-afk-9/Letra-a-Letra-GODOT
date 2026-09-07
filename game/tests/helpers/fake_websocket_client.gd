extends WebSocketClient
class_name FakeWebSocketClient

func _init() -> void:
	# provider dummy — não usado nos testes de buffering
	super._init(preload("res://tests/helpers/fake_auth_provider.gd").new())

func emit_message_dict(dict: Dictionary) -> void:
	message_received.emit(WebSocketMessage.from_dictionary(dict))
