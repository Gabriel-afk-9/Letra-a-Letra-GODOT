extends RefCounted

class_name MatchmakingUseCase


signal searching
signal search_cancelled
signal match_found(event: MatchmakingFoundEvent)
signal error(message: String)


var _repository: MatchmakingRepository


func _init(
	repository: MatchmakingRepository
) -> void:

	_repository = repository
	
	_repository.searching.connect(_on_searching)
	_repository.search_cancelled.connect(_on_search_cancelled)
	_repository.match_found.connect(_on_match_found)
	_repository.error.connect(_on_error)


func _on_searching() -> void:
	searching.emit()


func _on_search_cancelled() -> void:
	search_cancelled.emit()


func _on_match_found(
	event: MatchmakingFoundEvent
) -> void:
	match_found.emit(event)


func _on_error(
	message: String
) -> void:
	error.emit(message)
