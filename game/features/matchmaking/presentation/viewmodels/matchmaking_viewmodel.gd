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
signal navigate_to_game


var _state: MatchmakingState = MatchmakingState.IDLE

var _usecase: MatchmakingUseCase


func _init(
	usecase: MatchmakingUseCase
) -> void:

	_usecase = usecase

	_usecase.searching.connect(_on_searching)

	_usecase.search_cancelled.connect(_on_search_cancelled)

	_usecase.match_found.connect(_on_match_found)

	_usecase.error.connect(_on_error)


func state() -> MatchmakingState:
	return _state


func start_search() -> void:

	_clear_error()

	_usecase.start_search()


func cancel_search() -> void:

	_usecase.cancel_search()


func _set_state(
	new_state: MatchmakingState
) -> void:

	if _state == new_state:
		return

	_state = new_state

	state_changed.emit(new_state)


func _on_searching() -> void:

	_set_state(
		MatchmakingState.SEARCHING
	)


func _on_search_cancelled() -> void:

	_set_state(
		MatchmakingState.IDLE
	)


func _on_error(
	message: String
) -> void:

	_set_error(message)

	_set_state(
		MatchmakingState.ERROR
	)


func _on_match_found(
	event: MatchmakingFoundEvent
) -> void:

	_set_state(
		MatchmakingState.FOUND
	)

	opponent_found.emit(event)

	await (
		Engine.get_main_loop() as SceneTree
	).create_timer(2.0).timeout

	if _state != MatchmakingState.FOUND:
		return

	_set_state(
		MatchmakingState.CONNECTING
	)

	navigate_to_game.emit()
