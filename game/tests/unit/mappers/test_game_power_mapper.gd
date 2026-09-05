extends GutTest


func test_power_freeze_without_rarity_fallback() -> void:
	var power := GamePowerMapper.to_domain({"id": "1", "name": "FREEZE"})

	assert_eq(power.id, "1")
	assert_eq(power.type, "FREEZE")
	assert_eq(power.rarity, GamePowerCatalog.RARITY_RARE)


func test_power_with_explicit_rarity() -> void:
	var power := GamePowerMapper.to_domain({"id": "2", "name": "BLOCK", "rarity": "LEGENDARY"})

	assert_eq(power.rarity, "LEGENDARY")


func test_power_null_fields() -> void:
	var power := GamePowerMapper.to_domain({})

	assert_eq(power.id, "")
	assert_eq(power.type, "")
	# type vazio → get_rarity retorna ""
	assert_eq(power.rarity, "")
