extends GutTest

var _users: FakeUserRepository
var _vm: HomeViewModel


func before_each() -> void:
	_users = FakeUserRepository.new()
	var usecase := GetCurrentUserUseCase.new(_users, SessionStore)
	_vm = HomeViewModel.new(usecase, NavigationService.new(), InitialDataStore.new())


func _avatar(item_id: String, equipped: bool) -> InventoryItem:
	return InventoryItem.from_dictionary({
		"itemId": item_id,
		"name": "Avatar",
		"kind": "EQUIPPABLE",
		"category": "AVATAR",
		"context": "PROFILE",
		"quantity": 1,
		"equipped": equipped,
		"assetPath": "AVATAR/ceo.webp",
	})


func test_equipped_avatar_item_returns_equipped_avatar() -> void:
	_vm._data_store.set_inventory([
		_avatar("a-1", false),
		_avatar("a-2", true),
	])

	var item := _vm.equipped_avatar_item()

	assert_not_null(item, "encontra o avatar equipado")
	assert_eq(item.item_id, "a-2", "id correto")
	assert_eq(item.asset_path, "AVATAR/ceo.webp", "asset real preservado")


func test_equipped_avatar_item_without_equipped_returns_null() -> void:
	_vm._data_store.set_inventory([_avatar("a-1", false)])

	assert_null(_vm.equipped_avatar_item(), "sem equipado retorna nulo")


func test_equipped_avatar_item_without_store_returns_null() -> void:
	var usecase := GetCurrentUserUseCase.new(_users, SessionStore)
	var storeless := HomeViewModel.new(usecase, NavigationService.new(), null)

	assert_null(storeless.equipped_avatar_item(), "sem store retorna nulo")
