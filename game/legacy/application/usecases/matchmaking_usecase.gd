extends RefCounted
class_name MatchmakingUseCase

var ws_manager: Node
var auth_manager: Node
var environment: Node

func _init() -> void:
	ws_manager = Engine.get_main_loop().root.get_node("WebSocketManager")
	auth_manager = Engine.get_main_loop().root.get_node("AuthManager")
	environment = Engine.get_main_loop().root.get_node("GlobalEnvironment")

func execute() -> void:
	var token = auth_manager.user_token
	
	var ws_url = environment.WS_BASE_URL + "?token=" + token
	
	if not ws_manager.connected.is_connected(_on_ws_connected):
		ws_manager.connected.connect(_on_ws_connected)

	ws_manager.connect_to_server(ws_url)

func _on_ws_connected() -> void:
	ws_manager.connected.disconnect(_on_ws_connected)
	
	ws_manager.send_action("MATCHMAKING_GAME")
