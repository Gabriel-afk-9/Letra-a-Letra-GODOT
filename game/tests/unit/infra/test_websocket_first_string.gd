extends GutTest

func test_first_string_root_wins_over_data() -> void:
	var msg := WebSocketMessage.from_dictionary({
		"currentTurnPlayerId": "root-id",
		"data": {"currentTurnPlayerId": "data-id"}
	})
	# WebSocketMessage.raw tem root; _first_string checa raw primeiro
	assert_true(msg.has("currentTurnPlayerId"))
	assert_eq(msg.get_string("currentTurnPlayerId"), "root-id")

func test_first_string_fallback_to_data() -> void:
	var msg := WebSocketMessage.from_dictionary({
		"data": {"currentTurnPlayerId": "only-data", "turnEndsAt": "2026-09-04T12:00:00Z"}
	})
	assert_false(msg.has("currentTurnPlayerId"))
	assert_eq(str(msg.data.get("currentTurnPlayerId", "")), "only-data")
	assert_eq(str(msg.data.get("turnEndsAt", "")), "2026-09-04T12:00:00Z")

func test_first_string_missing_returns_empty() -> void:
	var msg := WebSocketMessage.from_dictionary({"event": "TURN_EXPIRED", "data": {}})
	assert_false(msg.has("currentTurnPlayerId"))
	assert_eq(str(msg.data.get("currentTurnPlayerId", "")), "")

func test_websocket_message_has_get_string_raw() -> void:
	var msg := WebSocketMessage.from_dictionary({"event": "ERROR", "message": "stepped_on_trap", "data": {"x": 1}})
	assert_eq(msg.event, "ERROR")
	assert_eq(msg.message, "stepped_on_trap")
	assert_true(msg.has("event"))
	assert_eq(msg.get_string("message"), "stepped_on_trap")
	assert_eq(msg.data.get("x"), 1)
