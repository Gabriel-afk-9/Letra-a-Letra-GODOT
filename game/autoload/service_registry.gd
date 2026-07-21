extends Node

var _session_persistence: SessionPersistence
var _http_client: HttpClient
var _navigation_service: NavigationService


func _ready() -> void:
	_register_dependencies()


func _register_dependencies() -> void:

	# Persistência
	_session_persistence = SessionPersistence.new()

	# Cliente HTTP
	_http_client = HttpClient.new(SessionStore)
	add_child(_http_client)

	# Navegação
	_navigation_service = NavigationService.new()


# ============================================================================
# Getters
# ============================================================================

func session_persistence() -> SessionPersistence:
	return _session_persistence


func http_client() -> HttpClient:
	return _http_client


func navigation_service() -> NavigationService:
	return _navigation_service
