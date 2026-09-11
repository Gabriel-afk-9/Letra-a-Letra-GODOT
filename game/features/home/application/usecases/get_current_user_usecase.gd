extends RefCounted
class_name GetCurrentUserUseCase

var _user_repository: UserRepository
var _session_store

func _init(user_repository: UserRepository, session_store) -> void:
	_user_repository = user_repository
	_session_store = session_store

func execute() -> User:
	var token: String = _session_store.get_token()
	if token.is_empty():
		return null
	return await _user_repository.fetch_current_user(token)
