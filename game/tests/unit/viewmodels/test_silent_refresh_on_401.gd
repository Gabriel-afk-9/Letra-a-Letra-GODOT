extends GutTest


class SequencedUserRepository:
	extends UserRepository
	var user: User = null
	var profile_calls := 0
	var fail_first_with_401 := true

	func fetch_current_user(_access_token: String) -> User:
		return user

	func fetch_current_user_result(_access_token: String) -> Dictionary:
		profile_calls += 1
		if fail_first_with_401 and profile_calls == 1:
			return {"user": null, "status_code": 401, "error": "Unauthorized"}
		return {"user": user, "status_code": 200}


class FakeLoginRepository:
	extends LoginRepository
	var refresh_result: LoginResult = LoginResult.new(true, null, "fresh-access", "", "fresh-refresh")
	var refresh_calls: Array = []

	func refresh(refresh_token: String) -> LoginResult:
		refresh_calls.append(refresh_token)
		return refresh_result


class FakeSessionStore:
	extends RefCounted
	var user: User = null
	var token := "stale-access"
	var refresh := "stored-refresh"

	func get_token() -> String:
		return token

	func get_refresh_token() -> String:
		return refresh

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


var _users: SequencedUserRepository
var _login: FakeLoginRepository
var _session: FakeSessionStore
var _store: InitialDataStore
var _usecase: LoadInitialDataUseCase


func before_each() -> void:
	_users = SequencedUserRepository.new()
	_users.user = User.new("u-1", "jogador@lal.gg", "Nick")
	_login = FakeLoginRepository.new()
	_session = FakeSessionStore.new()
	_store = InitialDataStore.new()
	_usecase = LoadInitialDataUseCase.new(
		_users,
		FakeShopRepository.new(),
		FakeInventoryRepository.new(),
		FakeFriendRepository.new(),
		_session,
		_store,
		_login
	)


func test_expired_access_token_refreshes_once_and_succeeds() -> void:
	var result: LoadingResult = await _usecase.execute()

	assert_true(result.success)
	assert_false(result.unauthorized)
	assert_eq(_users.profile_calls, 2)
	assert_eq(_login.refresh_calls, ["stored-refresh"])
	assert_eq(_session.token, "fresh-access")
	assert_eq(_session.refresh, "fresh-refresh")
	assert_true(_store.is_ready())


func test_failed_refresh_keeps_unauthorized() -> void:
	_login.refresh_result = LoginResult.new(false, null, "", "Refresh expirado.")

	var result: LoadingResult = await _usecase.execute()

	assert_false(result.success)
	assert_true(result.unauthorized)
	assert_eq(result.failed_group, "perfil")
