extends BaseViewModel
class_name MatchmakingViewModel

enum MatchmakingState {
	IDLE,
	SEARCHING,
	FOUND,
	CONNECTING,
	ERROR
}

signal state_changed(state: MatchmakingState)
signal opponent_found(event: MatchmakingFoundEvent)

var _state: MatchmakingState = MatchmakingState.IDLE
var _usecase: MatchmakingUseCase
var _navigation: NavigationService
var _pending_navigation_payload: PendingNavigationPayload


func _init(usecase: MatchmakingUseCase, navigation: NavigationService, pending_navigation_payload: PendingNavigationPayload) -> void:
	_usecase = usecase
	_navigation = navigation
	_pending_navigation_payload = pending_navigation_payload

	_usecase.searching.connect(_on_searching)
	_usecase.search_cancelled.connect(_on_search_cancelled)
	_usecase.match_found.connect(_on_match_found)
	_usecase.error.connect(_on_error)



func state() -> MatchmakingState:
	return _state

func current_player_nickname() -> String:
	return _usecase.current_player_nickname()

func start_search() -> void:
	if _state == MatchmakingState.SEARCHING:
		return
	_clear_error()
	_usecase.start_search()

func cancel_search() -> void:
	_usecase.cancel_search()

var _ghost_retry_count: int = 0
const MAX_GHOST_RETRIES: int = 3

func force_leave_and_retry() -> void:
	var game_repo: GameRepository = ServiceRegistry.game_repository()
	var ws: WebSocketClient = ServiceRegistry.websocket_client()
	if game_repo.has_method("force_ghost_leave"):
		game_repo.force_ghost_leave()
	else:
		game_repo.leave_game()
	ws.disconnect_socket()
	_clear_error()
	_ghost_retry_count += 1
	if _ghost_retry_count > MAX_GHOST_RETRIES:
		_set_error("Não foi possível sair da partida. Voltando ao início.")
		_set_state(MatchmakingState.ERROR)
		await (Engine.get_main_loop() as SceneTree).create_timer(1.5).timeout
		_navigation.go_to(AppRoutes.SHELL)
		return
	await (Engine.get_main_loop() as SceneTree).create_timer(0.8).timeout
	if ws.is_socket_connected():
		ws.disconnect_socket()
		await (Engine.get_main_loop() as SceneTree).create_timer(0.4).timeout
	start_search()

func is_already_in_game_error() -> bool:
	var msg: String = error_message()
	if msg.is_empty():
		return false
	return msg.to_lower().contains("already in a game")



func _set_state(new_state: MatchmakingState) -> void:
	if _state == new_state:
		return
	_state = new_state
	state_changed.emit(new_state)

func _on_searching() -> void:
	_ghost_retry_count = 0
	_set_state(MatchmakingState.SEARCHING)

func _on_search_cancelled() -> void:
	_ghost_retry_count = 0
	_set_state(MatchmakingState.IDLE)
	_navigation.go_to(AppRoutes.SHELL)

func _on_error(message: String) -> void:
	if not message.to_lower().contains("already in a game"):
		_ghost_retry_count = 0
	_set_error(message)
	_set_state(MatchmakingState.ERROR)

func _on_match_found(event: MatchmakingFoundEvent) -> void:
	_set_state(MatchmakingState.FOUND)
	opponent_found.emit(event)

	await (Engine.get_main_loop() as SceneTree).create_timer(2.0).timeout

	if _state != MatchmakingState.FOUND:
		return

	_set_state(MatchmakingState.CONNECTING)
	_pending_navigation_payload.set_payload(event)
	_navigation.go_to(AppRoutes.GAME)
