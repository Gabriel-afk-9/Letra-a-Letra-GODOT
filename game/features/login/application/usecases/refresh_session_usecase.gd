extends RefCounted
class_name RefreshSessionUseCase

var _login_repository: LoginRepository
var _user_repository: UserRepository
var _session_store
var _persistence: SessionPersistence = null

func _init(
	login_repository: LoginRepository,
	user_repository: UserRepository,
	session_store,
	persistence: SessionPersistence = null
) -> void:
	_login_repository = login_repository
	_user_repository = user_repository
	_session_store = session_store
	_persistence = persistence


func execute(refresh_token: String = "") -> LoginResult:
	var stored_refresh := refresh_token
	if stored_refresh.is_empty() and _session_store.has_method("get_refresh_token"):
		stored_refresh = str(_session_store.get_refresh_token())
	if stored_refresh.is_empty():
		_session_store.end_session()
		if _persistence != null:
			_persistence.clear()
		return LoginResult.new(false, null, "", "Sessão expirada. Entre novamente.")

	var result: LoginResult = await _login_repository.refresh(stored_refresh)

	if not result.success:
		_session_store.end_session()
		if _persistence != null:
			_persistence.clear()
		return result

	var user := await _user_repository.fetch_current_user(result.access_token)

	if user == null:
		return LoginResult.new(false, null, "", "Unable to load user profile.")

	_session_store.start_session(user, result.access_token, result.refresh_token)
	if _persistence != null:
		_persistence.save(_session_store)

	return LoginResult.new(true, user, result.access_token, result.message, result.refresh_token)
