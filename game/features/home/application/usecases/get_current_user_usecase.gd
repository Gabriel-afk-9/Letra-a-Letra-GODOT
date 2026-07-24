extends RefCounted
class_name GetCurrentUserUseCase

var _session_store

func _init(session_store) -> void:
	_session_store = session_store

func execute() -> User:
	return _session_store.get_user()
