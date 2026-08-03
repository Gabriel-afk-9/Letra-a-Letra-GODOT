extends CurrentUserProvider
class_name SessionStoreCurrentUserProvider


var _session_store: SessionStore


func _init(session_store: SessionStore) -> void:
	_session_store = session_store


func current_user() -> User:
	return _session_store.get_user()
