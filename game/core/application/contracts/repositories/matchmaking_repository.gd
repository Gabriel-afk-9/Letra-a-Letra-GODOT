extends RefCounted

class_name MatchmakingRepository


signal searching
signal search_cancelled
signal match_found(event: MatchmakingFoundEvent)
signal error(message: String)


func start_search() -> void:
	push_error("MatchmakingRepository.start_search() must be implemented.")


func cancel_search() -> void:
	push_error("MatchmakingRepository.cancel_search() must be implemented.")
