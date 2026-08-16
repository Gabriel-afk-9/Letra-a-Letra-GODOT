extends Node

var _initialized: bool = false

var _session_persistence: SessionPersistence
var _http_client: HttpClient
var _navigation_service: NavigationService
var _pending_navigation_payload: PendingNavigationPayload
var _websocket_client: WebSocketClient
var _matchmaking_repository: RemoteMatchmakingRepository
var _game_repository: RemoteGameRepository
var _user_repository: RemoteUserRepository
var _current_user_provider: CurrentUserProvider

func _enter_tree() -> void:
	if _initialized: return
	_initialized = true
	
	_session_persistence = SessionPersistence.new()
	var auth_adapter = SessionStoreAuthProvider.new(SessionStore)
	
	_http_client = HttpClient.new(auth_adapter)
	add_child(_http_client)
	
	_user_repository = RemoteUserRepository.new(
	_http_client)
	
	
	_websocket_client = WebSocketClient.new(auth_adapter)
	add_child(_websocket_client)
	
	_navigation_service = NavigationService.new()
	_pending_navigation_payload = PendingNavigationPayload.new()
	
	_current_user_provider = SessionStoreCurrentUserProvider.new(SessionStore)
	_matchmaking_repository = RemoteMatchmakingRepository.new(_websocket_client, _current_user_provider)
	_game_repository = RemoteGameRepository.new(_websocket_client, _current_user_provider)

func session_persistence() -> SessionPersistence:
	return _session_persistence

func http_client() -> HttpClient:
	return _http_client

func user_repository() -> UserRepository:
	return _user_repository
	
func websocket_client() -> WebSocketClient:
	return _websocket_client

func navigation_service() -> NavigationService:
	return _navigation_service

func pending_navigation_payload() -> PendingNavigationPayload:
	return _pending_navigation_payload

func matchmaking_repository() -> MatchmakingRepository:
	return _matchmaking_repository


func game_repository() -> GameRepository:
	return _game_repository

func current_user_provider() -> CurrentUserProvider:
	return _current_user_provider
