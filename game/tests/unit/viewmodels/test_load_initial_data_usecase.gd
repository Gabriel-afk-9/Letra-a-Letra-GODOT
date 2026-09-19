extends GutTest


class FakeSessionStore:
	extends RefCounted
	var token := "fake-token"
	var user: User = null
	var started := 0

	func get_token() -> String:
		return token

	func start_session(p_user: User, p_token: String) -> void:
		user = p_user
		token = p_token
		started += 1


var _users: FakeUserRepository
var _shop: FakeShopRepository
var _inventory: FakeInventoryRepository
var _friends: FakeFriendRepository
var _session: FakeSessionStore
var _store: InitialDataStore
var _usecase: LoadInitialDataUseCase


func before_each() -> void:
	_users = FakeUserRepository.new()
	_shop = FakeShopRepository.new()
	_inventory = FakeInventoryRepository.new()
	_friends = FakeFriendRepository.new()
	_session = FakeSessionStore.new()
	_store = InitialDataStore.new()
	_usecase = LoadInitialDataUseCase.new(_users, _shop, _inventory, _friends, _session, _store)


func _make_user() -> User:
	return User.new("u-1", "jogador@lal.gg", "Nick", 10, 67, 100, 1, 15, 2, 100)


func test_success_populates_store_and_reports_progress() -> void:
	_users.scripted_profile_result = {"user": _make_user(), "status_code": 200}
	_shop.offers_result = {"offers": [ShopOffer.new("o-1", "Pacote")], "status_code": 200}
	_inventory.inventory_result = {"items": [InventoryItem.new("i-1", "Avatar")], "status_code": 200}
	_friends.friends_result = {"friends": [], "page": 0, "total_pages": 1, "total_elements": 0}

	var steps: Array = []
	var result: LoadingResult = await _usecase.execute(func(completed: int, total: int, _group: String) -> void: steps.append([completed, total]))

	assert_true(result.success)
	assert_eq(steps, [[1, 4], [2, 4], [3, 4], [4, 4]])
	assert_true(_store.is_ready())
	assert_eq(_store.get_user().nickname, "Nick")
	assert_eq(_store.get_offers().size(), 1)
	assert_eq(_store.get_inventory().size(), 1)
	assert_eq(_session.started, 1)


func test_single_group_failure_returns_group_error() -> void:
	_users.scripted_profile_result = {"user": _make_user(), "status_code": 200}
	_shop.offers_result = {"error": "boom", "status_code": 500}
	_inventory.inventory_result = {"items": [], "status_code": 200}

	var steps: Array = []
	var result: LoadingResult = await _usecase.execute(func(completed: int, total: int, _group: String) -> void: steps.append(completed))

	assert_false(result.success)
	assert_eq(result.failed_group, "loja")
	assert_eq(result.message, "Não foi possível carregar a loja.")
	assert_false(result.unauthorized)
	assert_eq(steps, [1, 2, 3])
	assert_false(_store.is_ready())


func test_unauthorized_flags_session_expired() -> void:
	_users.scripted_profile_result = {"user": null, "status_code": 401, "error": "Unauthorized"}

	var result: LoadingResult = await _usecase.execute()

	assert_false(result.success)
	assert_true(result.unauthorized)
	assert_eq(result.failed_group, "perfil")


func test_empty_token_is_unauthorized() -> void:
	_session.token = ""

	var result: LoadingResult = await _usecase.execute()

	assert_false(result.success)
	assert_true(result.unauthorized)
