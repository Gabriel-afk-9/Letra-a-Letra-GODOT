extends RefCounted
class_name LoginUseCase

var _login_repository: LoginRepository
var _user_repository: UserRepository
var _session_store

func _init(
	login_repository: LoginRepository,
	user_repository: UserRepository,
	session_store
) -> void:
	_login_repository = login_repository
	_user_repository = user_repository
	_session_store = session_store

func execute(email: String, password: String) -> LoginResult:
	var request := LoginRequest.new(email, password)
	var result: LoginResult = await _login_repository.login(request)

	if not result.success:
		return result

	var user := await _user_repository.fetch_current_user(result.access_token)

	if user == null:
		return LoginResult.new(false, null, "", "Unable to load user profile.")

	_session_store.start_session(user, result.access_token)

	return LoginResult.new(true, user, result.access_token, result.message)
