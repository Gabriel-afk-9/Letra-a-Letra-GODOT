extends GutTest


class FakeLoginRepository:
	extends LoginRepository
	var refresh_result: LoginResult = LoginResult.new(false, null, "", "Sem sessão.")
	var refresh_calls: Array = []

	func refresh(refresh_token: String) -> LoginResult:
		refresh_calls.append(refresh_token)
		return refresh_result

	func logout() -> bool:
		return true


class FakeSessionStore:
	extends RefCounted
	var user: User = null
	var token := ""
	var refresh := ""
	var ended := 0

	func is_authenticated() -> bool:
		return user != null and not token.is_empty()

	func get_token() -> String:
		return token

	func get_refresh_token() -> String:
		return refresh

	func has_refresh_token() -> bool:
		return not refresh.is_empty()

	func get_user() -> User:
		return user

	func start_session(p_user: User, p_token: String, p_refresh: String = "") -> void:
		user = p_user
		token = p_token
		if not p_refresh.is_empty():
			refresh = p_refresh

	func set_tokens(p_token: String, p_refresh: String = "") -> void:
		token = p_token
		if not p_refresh.is_empty():
			refresh = p_refresh

	func end_session() -> void:
		user = null
		token = ""
		refresh = ""
		ended += 1


class FakePersistence:
	extends SessionPersistence
	var saves := 0
	var clears := 0

	func save(_store: Object) -> void:
		saves += 1

	func clear() -> void:
		clears += 1


var _login: FakeLoginRepository
var _users: FakeUserRepository
var _session: FakeSessionStore
var _persistence: FakePersistence
var _usecase: RefreshSessionUseCase


func before_each() -> void:
	_login = FakeLoginRepository.new()
	_users = FakeUserRepository.new()
	_session = FakeSessionStore.new()
	_persistence = FakePersistence.new()
	_usecase = RefreshSessionUseCase.new(_login, _users, _session, _persistence)


func _make_user() -> User:
	return User.new("u-1", "jogador@lal.gg", "Nick")


func test_refresh_rotates_tokens_and_persists() -> void:
	_login.refresh_result = LoginResult.new(true, null, "fresh-access", "ok", "fresh-refresh")
	_users.scripted_user = _make_user()
	_session.start_session(_make_user(), "stale-access", "stored-refresh")

	var result: LoginResult = await _usecase.execute()

	assert_true(result.success)
	assert_eq(result.access_token, "fresh-access")
	assert_eq(result.refresh_token, "fresh-refresh")
	assert_eq(_session.token, "fresh-access")
	assert_eq(_session.refresh, "fresh-refresh")
	assert_eq(_session.user.nickname, "Nick")
	assert_eq(_login.refresh_calls, ["stored-refresh"])
	assert_eq(_persistence.saves, 1)


func test_refresh_failure_clears_session_and_storage() -> void:
	_login.refresh_result = LoginResult.new(false, null, "", "Refresh expirado.")
	_session.start_session(_make_user(), "stale-access", "stored-refresh")

	var result: LoginResult = await _usecase.execute()

	assert_false(result.success)
	assert_eq(_session.ended, 1)
	assert_eq(_persistence.clears, 1)


func test_missing_refresh_token_fails_without_request() -> void:
	var result: LoginResult = await _usecase.execute()

	assert_false(result.success)
	assert_true(_login.refresh_calls.is_empty())
	assert_eq(_session.ended, 1)
	assert_eq(_persistence.clears, 1)
