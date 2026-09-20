extends GutTest


class FakeLoginRepository:
	extends LoginRepository
	var logout_calls := 0
	var logout_result := true

	func logout() -> bool:
		logout_calls += 1
		return logout_result


class FakeSessionStore:
	extends RefCounted
	var ended := 0

	func end_session() -> void:
		ended += 1


class FakePersistence:
	extends SessionPersistence
	var cleared := 0

	func clear() -> void:
		cleared += 1


class FakeNavigation:
	extends NavigationService
	var last_route := ""
	var go_count := 0

	func go_to(route: String) -> void:
		last_route = route
		go_count += 1


var _users: FakeUserRepository
var _login: FakeLoginRepository
var _session: FakeSessionStore
var _persistence: FakePersistence
var _navigation: FakeNavigation
var _store: InitialDataStore
var _vm: HomeViewModel


func before_each() -> void:
	_users = FakeUserRepository.new()
	_login = FakeLoginRepository.new()
	_session = FakeSessionStore.new()
	_persistence = FakePersistence.new()
	_navigation = FakeNavigation.new()
	_store = InitialDataStore.new()
	_store.set_inventory([])
	var usecase := GetCurrentUserUseCase.new(_users, SessionStore)
	_vm = HomeViewModel.new(usecase, _navigation, _store, _login, _session, _persistence)


func test_logout_calls_api_clears_session_and_goes_to_main() -> void:
	await _vm.logout_and_go_to_main()

	assert_eq(_login.logout_calls, 1, "deve enviar logout à API")
	assert_eq(_session.ended, 1, "deve encerrar a sessão em memória")
	assert_eq(_persistence.cleared, 1, "deve apagar os tokens persistidos")
	assert_false(_store.is_inventory_loaded(), "deve limpar o cache inicial")
	assert_eq(_navigation.last_route, AppRoutes.MAIN, "deve navegar para a main")
	assert_eq(_navigation.go_count, 1)


func test_logout_failure_still_clears_local_session() -> void:
	_login.logout_result = false

	await _vm.logout_and_go_to_main()

	assert_eq(_login.logout_calls, 1)
	assert_eq(_session.ended, 1, "sessão local deve ser encerrada mesmo com falha na API")
	assert_eq(_navigation.last_route, AppRoutes.MAIN)
