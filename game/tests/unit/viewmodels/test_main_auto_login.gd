extends GutTest


class FakeLoginRepository:
	extends LoginRepository
	var refresh_result: LoginResult = LoginResult.new(true, null, "fresh-access", "", "fresh-refresh")

	func refresh(_refresh_token: String) -> LoginResult:
		return refresh_result


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

	func end_session() -> void:
		user = null
		token = ""
		refresh = ""
		ended += 1


class FakeNavigation:
	extends NavigationService
	var last_route := ""
	var go_count := 0

	func go_to(route: String) -> void:
		last_route = route
		go_count += 1


var _login: FakeLoginRepository
var _users: FakeUserRepository
var _session: FakeSessionStore
var _navigation: FakeNavigation
var _vm: MainViewModel


func before_each() -> void:
	_login = FakeLoginRepository.new()
	_users = FakeUserRepository.new()
	_users.scripted_user = User.new("u-1", "jogador@lal.gg", "Nick")
	_session = FakeSessionStore.new()
	_navigation = FakeNavigation.new()
	var usecase := RefreshSessionUseCase.new(_login, _users, _session)
	_vm = MainViewModel.new(_navigation, usecase, _session)


func test_stored_refresh_token_logs_in_and_goes_to_loading() -> void:
	_session.refresh = "stored-refresh"

	var ok: bool = await _vm.try_auto_login()

	assert_true(ok)
	assert_eq(_session.token, "fresh-access")
	assert_eq(_navigation.last_route, AppRoutes.LOADING)
	assert_eq(_navigation.go_count, 1)


func test_without_refresh_token_stays_on_main() -> void:
	var ok: bool = await _vm.try_auto_login()

	assert_false(ok)
	assert_eq(_navigation.go_count, 0)


func test_invalid_refresh_stays_on_main() -> void:
	_session.refresh = "stored-refresh"
	_login.refresh_result = LoginResult.new(false, null, "", "Refresh expirado.")

	var ok: bool = await _vm.try_auto_login()

	assert_false(ok)
	assert_eq(_navigation.go_count, 0)
	assert_eq(_session.ended, 1)
