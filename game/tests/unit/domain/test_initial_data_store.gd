extends GutTest


func test_is_ready_only_when_all_groups_loaded() -> void:
	var store := InitialDataStore.new()
	assert_false(store.is_ready())

	store.set_user(User.new("u-1", "a@b.c", "Nick"))
	assert_false(store.is_ready())
	store.set_offers([])
	assert_false(store.is_ready())
	store.set_inventory([])
	assert_false(store.is_ready())

	store.set_friends([], 0, 1, 0)
	assert_false(store.is_ready())
	store.mark_friends_loaded()
	assert_true(store.is_ready())


func test_clear_resets_everything() -> void:
	var store := InitialDataStore.new()
	store.set_user(User.new("u-1", "a@b.c", "Nick"))
	store.set_offers([ShopOffer.new("o-1")])
	store.set_inventory([InventoryItem.new("i-1")])
	store.set_friends([], 0, 1, 0)
	store.set_pending([])
	store.set_sent([])
	store.mark_friends_loaded()
	assert_true(store.is_ready())

	store.clear()

	assert_false(store.is_ready())
	assert_false(store.has_user())
	assert_null(store.get_user())
	assert_eq(store.get_offers(), [])
	assert_eq(store.get_inventory(), [])
	assert_eq(store.get_friends(), [])
	assert_eq(store.get_pending(), [])
	assert_eq(store.get_sent(), [])
