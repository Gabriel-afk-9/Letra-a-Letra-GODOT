extends GutTest

# fixtures do contrato docs/websocket-events-contract.md:1
# Fallback inline Dictionary caso FileAccess falhe headless

func _load_fixture(path: String, fallback: Dictionary) -> Dictionary:
	if FileAccess.file_exists(path):
		var text := FileAccess.get_file_as_string(path)
		var decoded: Variant = JsonSerializer.decode(text)
		if decoded is Dictionary and not (decoded as Dictionary).is_empty():
			return decoded as Dictionary
	return fallback

func test_player_action_result_root_turnEndsAt() -> void:
	var dict := _load_fixture("res://tests/fixtures/ws_player_action_result_root.json", {
		"event": "PLAYER_ACTION_RESULT",
		"turnEndsAt": "2026-09-04T12:00:00Z",
		"events": [],
		"data": {"players": [], "board": [[{"revealed": true, "letter": "A"}]], "words": [], "currentTurnPlayerId": "me"}
	})
	var msg := WebSocketMessage.from_dictionary(dict)
	assert_eq(msg.event, "PLAYER_ACTION_RESULT")
	assert_true(msg.has("turnEndsAt"))
	assert_eq(msg.get_string("turnEndsAt"), "2026-09-04T12:00:00Z")

func test_player_action_result_data_turnEndsAt() -> void:
	var dict := _load_fixture("res://tests/fixtures/ws_player_action_result_data.json", {
		"event": "PLAYER_ACTION_RESULT",
		"events": [],
		"data": {"currentTurnPlayerId": "me", "turnEndsAt": "2026-09-04T12:00:00Z"}
	})
	var msg := WebSocketMessage.from_dictionary(dict)
	assert_eq(msg.event, "PLAYER_ACTION_RESULT")
	assert_false(msg.has("turnEndsAt"))
	assert_eq(str(msg.data.get("turnEndsAt", "")), "2026-09-04T12:00:00Z")

func test_turn_expired_has_data_user_and_currentTurn() -> void:
	var dict := _load_fixture("res://tests/fixtures/ws_turn_expired.json", {
		"event": "TURN_EXPIRED",
		"data": {"user": "u1", "currentTurnPlayerId": "u2"}
	})
	var msg := WebSocketMessage.from_dictionary(dict)
	assert_eq(msg.event, "TURN_EXPIRED")
	assert_false(str(msg.data.get("user", "")).is_empty())
	assert_false(str(msg.data.get("currentTurnPlayerId", "")).is_empty())

func test_game_over_winner() -> void:
	var dict := _load_fixture("res://tests/fixtures/ws_game_over.json", {
		"event": "GAME_OVER",
		"data": {"winner": {"id": "me"}, "loser": {"id": "opp"}}
	})
	var msg := WebSocketMessage.from_dictionary(dict)
	assert_eq(msg.event, "GAME_OVER")
	assert_eq(str(msg.data.get("winner", {}).get("id", "")), "me")

func test_matchmaking_searching() -> void:
	var dict := _load_fixture("res://tests/fixtures/ws_matchmaking_searching.json", {
		"event": "MATCHMAKING_GAME", "status": "SEARCHING"
	})
	var msg := WebSocketMessage.from_dictionary(dict)
	assert_eq(msg.event, "MATCHMAKING_GAME")
	assert_eq(msg.get_string("status"), "SEARCHING")

func test_matchmaking_founded() -> void:
	var dict := _load_fixture("res://tests/fixtures/ws_matchmaking_founded.json", {
		"event": "MATCHMAKING_GAME", "status": "FOUNDED", "turnEndsAt": "2026-09-04T12:00:00Z", "gameId": "g1", "data": {}
	})
	var msg := WebSocketMessage.from_dictionary(dict)
	assert_eq(msg.event, "MATCHMAKING_GAME")
	assert_eq(msg.get_string("status"), "FOUNDED")
	assert_false(msg.get_string("gameId").is_empty())

func test_participant_disconnected_has_user() -> void:
	var dict := _load_fixture("res://tests/fixtures/ws_participant_disconnected.json", {
		"event": "PARTICIPANT_DISCONNECTED", "user": "opp"
	})
	var msg := WebSocketMessage.from_dictionary(dict)
	assert_eq(msg.event, "PARTICIPANT_DISCONNECTED")
	assert_false(msg.get_string("user").is_empty())

func test_removed_inactivity_only_event() -> void:
	var dict := _load_fixture("res://tests/fixtures/ws_removed_inactivity.json", {
		"event": "REMOVED_BECAUSE_INACTIVITY"
	})
	var msg := WebSocketMessage.from_dictionary(dict)
	assert_eq(msg.event, "REMOVED_BECAUSE_INACTIVITY")

func test_error_stepped_on_trap() -> void:
	var dict := _load_fixture("res://tests/fixtures/ws_error_stepped_on_trap.json", {
		"event": "ERROR", "message": "stepped_on_trap", "data": {"x": 1, "y": 2}
	})
	var msg := WebSocketMessage.from_dictionary(dict)
	assert_eq(msg.event, "ERROR")
	assert_eq(msg.message, "stepped_on_trap")
	assert_eq(int(msg.data.get("x", -1)), 1)
	assert_eq(int(msg.data.get("y", -1)), 2)

func test_error_already_revealed() -> void:
	var dict := _load_fixture("res://tests/fixtures/ws_error_already_revealed.json", {
		"event": "ERROR", "message": "the selected cell has already been revealed"
	})
	var msg := WebSocketMessage.from_dictionary(dict)
	assert_eq(msg.event, "ERROR")
	assert_eq(msg.message, "the selected cell has already been revealed")
