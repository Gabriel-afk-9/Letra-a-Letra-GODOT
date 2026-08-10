extends RefCounted
class_name MatchmakingUseCase


signal searching
signal search_cancelled
signal match_found(event: MatchmakingFoundEvent)
signal error(message: String)

var _repository: MatchmakingRepository
var _current_user_provider: CurrentUserProvider


func _init(repository: MatchmakingRepository, current_user_provider: CurrentUserProvider) -> void:
	_repository = repository
	_current_user_provider = current_user_provider

	_repository.searching.connect(_on_searching)
	_repository.search_cancelled.connect(_on_search_cancelled)
	_repository.match_found.connect(_on_match_found)
	_repository.error.connect(_on_error)


# Public API

func start_search() -> void:
	_repository.start_search()


func cancel_search() -> void:
	_repository.cancel_search()


func current_player_nickname() -> String:
	var user := _current_user_provider.current_user()
	return user.nickname if user != null else ""


# Internal

func _on_searching() -> void:
	searching.emit()


func _on_search_cancelled() -> void:
	search_cancelled.emit()


func _on_match_found(event: MatchmakingFoundEvent) -> void:
	match_found.emit(event)


func _on_error(message: String) -> void:
	error.emit(message)
