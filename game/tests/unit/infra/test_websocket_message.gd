extends GutTest


func test_from_dictionary_error_with_data() -> void:
	var msg := WebSocketMessage.from_dictionary({"event": "ERROR", "message": "x", "data": {"y": 1}})

	assert_eq(msg.event, "ERROR")
	assert_eq(msg.message, "x")
	assert_eq(msg.data["y"], 1)
	assert_true(msg.has("event"))
	assert_eq(msg.get_string("event"), "ERROR")
	assert_eq(msg.raw["event"], "ERROR")


func test_from_dictionary_player_action_result_with_events() -> void:
	var msg := WebSocketMessage.from_dictionary({
		"event": "PLAYER_ACTION_RESULT",
		"turnEndsAt": "2026-08-23T12:00:00Z",
		"data": {"board": [], "words": []},
		"events": [{"event": "CELL_REVEALED", "data": {"revealedBy": "p1"}}]
	})

	assert_eq(msg.event, "PLAYER_ACTION_RESULT")
	assert_eq(msg.get_string("turnEndsAt"), "2026-08-23T12:00:00Z")
	assert_eq(msg.events.size(), 1)
	assert_eq(msg.data["board"].size(), 0)


func test_from_dictionary_missing_fields_defaults() -> void:
	var msg := WebSocketMessage.from_dictionary({})

	assert_eq(msg.event, "")
	assert_eq(msg.message, "")
	assert_eq(msg.data.size(), 0)
	assert_eq(msg.events.size(), 0)


func test_has_and_get_helpers() -> void:
	var msg := WebSocketMessage.from_dictionary({"event": "GAME_OVER", "data": {"winner": {"id": "p1"}}})

	assert_true(msg.has("event"))
	assert_false(msg.has("nonexistent"))
	assert_eq(msg.get_dictionary("data")["winner"]["id"], "p1")
	assert_eq(msg.get_array("events").size(), 0)
