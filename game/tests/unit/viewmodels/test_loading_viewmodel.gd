extends GutTest


class FakeSessionStore:
	extends RefCounted
	var token := "fake-token"
	var user: User = null
	var ended := 0

	func get_token() -> String:
		return token

	func start_session(p_user: User, p_token: String) -> void:
		user = p_user
		token = p_token

	func end_session() -> void:
		user = null
		token = ""
		ended += 1


class FakeNavigation:
	extends NavigationService
	var last_route := ""
	var go_count := 0

	func go_to(route: String) -> void:
		last_route = route
		go_count += 1

	func go_to_shell() -> void:
		last_route = AppRoutes.SHELL
		go_count += 1


var _users: FakeUserRepository
var _shop: FakeShopRepository
var _inventory: FakeInventoryRepository
var _friends: FakeFriendRepository
var _session: FakeSessionStore
var _store: InitialDataStore
var _navigation: FakeNavigation
var _vm: LoadingViewModel


func before_each() -> void:
	_users = FakeUserRepository.new()
	_shop = FakeShopRepository.new()
	_inventory = FakeInventoryRepository.new()
	_friends = FakeFriendRepository.new()
	_session = FakeSessionStore.new()
	_store = InitialDataStore.new()
	_navigation = FakeNavigation.new()
	var usecase := LoadInitialDataUseCase.new(_users, _shop, _inventory, _friends, _session, _store)
	_vm = LoadingViewModel.new(usecase, _navigation, _session, _store)


func test_success_emits_progress_and_goes_to_shell() -> void:
	_users.scripted_profile_result = {"user": User.new("u-1", "a@b.c", "Nick"), "status_code": 200}
	var progresses: Array = []
	_vm.progress_changed.connect(func(value: float) -> void: progresses.append(value))

	await _vm.start()

	assert_eq(_navigation.last_route, AppRoutes.SHELL)
	assert_eq(_navigation.go_count, 1)
	assert_eq(progresses.back(), 1.0)
	assert_true(progresses.size() >= 4)
	assert_false(_vm.has_error())


func test_generic_failure_stays_and_shows_retry_error() -> void:
	_users.scripted_profile_result = {"user": User.new("u-1", "a@b.c", "Nick"), "status_code": 200}
	_inventory.inventory_result = {"error": "Falha de conexão. Tente novamente.", "status_code": 0}
	var errors: Array = []
	_vm.error_changed.connect(func(message: String) -> void: errors.append(message))

	await _vm.start()

	assert_eq(_navigation.go_count, 0)
	assert_eq(errors.back(), "Não foi possível carregar o inventário.")
	assert_lt(_vm.progress(), 1.0)


func test_unauthorized_clears_session_and_goes_to_login() -> void:
	_users.scripted_profile_result = {"user": null, "status_code": 401, "error": "Unauthorized"}
	_store.set_user(User.new("u-1", "a@b.c", "Nick"))

	await _vm.start()

	assert_eq(_session.ended, 1)
	assert_false(_store.is_ready())
	assert_eq(_navigation.last_route, AppRoutes.LOGIN)


func test_retry_after_failure_navigates_on_success() -> void:
	_users.scripted_profile_result = {"user": null, "status_code": 500, "error": "Erro"}

	await _vm.start()
	assert_eq(_navigation.go_count, 0)

	_users.scripted_profile_result = {"user": User.new("u-1", "a@b.c", "Nick"), "status_code": 200}

	await _vm.retry()
	assert_eq(_navigation.last_route, AppRoutes.SHELL)
