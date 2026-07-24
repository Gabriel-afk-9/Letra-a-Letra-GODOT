extends Node

var _initialized: bool = false

var _session_persistence: SessionPersistence
var _http_client: HttpClient
var _navigation_service: NavigationService


func _enter_tree() -> void:
	if _initialized: return
	_initialized = true
	
	_session_persistence = SessionPersistence.new()
	
	var auth_adapter: SessionStoreAuthProvider = SessionStoreAuthProvider.new(SessionStore)
	_http_client = HttpClient.new(auth_adapter)
	add_child(_http_client)
	
	_navigation_service = NavigationService.new()


func session_persistence() -> SessionPersistence:
	return _session_persistence


func http_client() -> HttpClient:
	return _http_client


func navigation_service() -> NavigationService:
	return _navigation_service
