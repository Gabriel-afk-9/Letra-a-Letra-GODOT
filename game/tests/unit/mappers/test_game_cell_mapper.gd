extends GutTest


func test_cell_effect_null_results_empty_type() -> void:
	var cell := GameCellMapper.to_domain({"letter": "X", "revealed": true}, 2, 3)

	assert_eq(cell.effect_type, "")
	assert_eq(cell.effect_owner_id, "")
	assert_eq(cell.remaining_clicks, 0)
	assert_eq(cell.x, 2)
	assert_eq(cell.y, 3)


func test_cell_letter_null_results_empty() -> void:
	var cell := GameCellMapper.to_domain({"letter": null, "revealed": true}, 0, 0)

	assert_eq(cell.letter, "")
	assert_true(cell.revealed)


func test_cell_revealed_false_when_not_bool() -> void:
	var cell := GameCellMapper.to_domain({"letter": "A", "revealed": "true"}, 0, 0)

	assert_false(cell.revealed)


func test_cell_effect_with_owner_and_clicks() -> void:
	var cell := GameCellMapper.to_domain({
		"letter": "B",
		"revealed": false,
		"effect": {"effect": "TRAP", "ownerId": "p1", "remainingClicks": 3}
	}, 1, 1)

	assert_eq(cell.effect_type, "TRAP")
	assert_eq(cell.effect_owner_id, "p1")
	assert_eq(cell.remaining_clicks, 3)


func test_cell_remaining_clicks_float() -> void:
	var cell := GameCellMapper.to_domain({
		"effect": {"effect": "BLOCK", "remainingClicks": 2.7}
	}, 0, 0)

	assert_eq(cell.remaining_clicks, 2)
