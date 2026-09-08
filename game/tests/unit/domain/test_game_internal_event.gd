extends GutTest


func test_founded_cells_parsing() -> void:
	var event := GameInternalEvent.from_dictionary("WORD_FOUNDED", {"cells": [{"x": 1, "y": 2}, {"x": 1, "y": 3}], "foundedBy": "p1"})

	assert_eq(event.event_name, "WORD_FOUNDED")
	var cells := event.get_founded_cells()
	assert_eq(cells.size(), 2)
	assert_eq(cells[0], Vector2i(1, 2))
	assert_eq(cells[1], Vector2i(1, 3))
	assert_eq(event.get_founded_by_player_id(), "p1")


func test_founded_cells_empty_when_missing() -> void:
	var event := GameInternalEvent.from_dictionary("WORD_FOUNDED", {})

	assert_eq(event.get_founded_cells().size(), 0)


func test_founded_cells_ignores_invalid_entries() -> void:
	var event := GameInternalEvent.from_dictionary("WORD_FOUNDED", {"cells": [{"x": "a", "y": 1}, {"x": 2}]})
	assert_eq(event.get_founded_cells().size(), 0)


func test_contains_player_id() -> void:
	var event := GameInternalEvent.from_dictionary("PLAYER_FROZEN", {"playerId": "id1", "other": "x"})

	assert_true(event.contains_player_id("id1"))
	assert_false(event.contains_player_id("id2"))


func test_get_cell_coordinates() -> void:
	var event := GameInternalEvent.from_dictionary("TRAP_TRIGGERED", {"cell": {"x": 3, "y": 4}})

	assert_eq(event.get_cell_x(), 3)
	assert_eq(event.get_cell_y(), 4)


func test_get_cell_coordinates_missing() -> void:
	var event := GameInternalEvent.from_dictionary("TRAP_TRIGGERED", {})

	assert_eq(event.get_cell_x(), -1)
	assert_eq(event.get_cell_y(), -1)


func test_mapper_to_domain() -> void:
	var event := GameInternalEventMapper.to_domain({"event": "PLAYER_BLINDED", "data": {"playerId": "p1"}})

	assert_eq(event.event_name, "PLAYER_BLINDED")
	assert_true(event.contains_player_id("p1"))
