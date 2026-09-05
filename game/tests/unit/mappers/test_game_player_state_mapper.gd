extends GutTest


func test_inventory_with_null_and_trap() -> void:
	var state := GamePlayerStateMapper.to_domain({
		"id": "p1",
		"inventory": [null, {"id": "a", "name": "TRAP"}]
	})

	assert_eq(state.player_id, "p1")
	assert_eq(state.inventory.size(), GamePlayerState.INVENTORY_SIZE)
	assert_null(state.inventory[0])
	assert_not_null(state.inventory[1])
	var power: GamePower = state.inventory[1]
	assert_eq(power.type, "TRAP")
	# slots restantes preenchidos com null
	assert_null(state.inventory[2])
	assert_null(state.inventory[4])


func test_inventory_missing_results_all_null() -> void:
	var state := GamePlayerStateMapper.to_domain({"id": "p2"})

	assert_eq(state.inventory.size(), GamePlayerState.INVENTORY_SIZE)
	for i in GamePlayerState.INVENTORY_SIZE:
		assert_null(state.inventory[i])


func test_inventory_empty_array() -> void:
	var state := GamePlayerStateMapper.to_domain({"id": "p3", "inventory": []})

	assert_eq(state.inventory.size(), GamePlayerState.INVENTORY_SIZE)
	assert_null(state.inventory[0])
