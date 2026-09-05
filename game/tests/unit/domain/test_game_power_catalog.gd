extends GutTest


func test_freeze_is_offensive_global() -> void:
	assert_true(GamePowerCatalog.is_offensive(GamePowerCatalog.POWER_TYPE_FREEZE))
	assert_eq(GamePowerCatalog.get_scope(GamePowerCatalog.POWER_TYPE_FREEZE), GamePowerCatalog.SCOPE_GLOBAL)
	assert_eq(GamePowerCatalog.get_rarity(GamePowerCatalog.POWER_TYPE_FREEZE), GamePowerCatalog.RARITY_RARE)


func test_unfreeze_and_immunity_can_use_while_frozen() -> void:
	assert_true(GamePowerCatalog.can_use_while_frozen(GamePowerCatalog.POWER_TYPE_UNFREEZE))
	assert_true(GamePowerCatalog.can_use_while_frozen(GamePowerCatalog.POWER_TYPE_IMMUNITY))
	assert_false(GamePowerCatalog.can_use_while_frozen(GamePowerCatalog.POWER_TYPE_BLIND))
	assert_false(GamePowerCatalog.can_use_while_frozen(GamePowerCatalog.POWER_TYPE_BLOCK))


func test_unknown_type_fallback_global() -> void:
	assert_eq(GamePowerCatalog.get_scope("UNKNOWN"), GamePowerCatalog.SCOPE_GLOBAL)
	assert_false(GamePowerCatalog.is_offensive("UNKNOWN"))
	assert_false(GamePowerCatalog.can_use_while_frozen("UNKNOWN"))
	assert_eq(GamePowerCatalog.get_rarity("UNKNOWN"), "")


func test_all_known_types_have_rarity() -> void:
	for type in GamePowerCatalog.POWER_TABLE.keys():
		var rarity := GamePowerCatalog.get_rarity(str(type))
		assert_ne(rarity, "", "rarity missing for %s" % type)
