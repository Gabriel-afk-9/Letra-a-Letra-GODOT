extends GutTest

var _fake_ws: FakeWebSocketClient
var _repo: RemoteRoomRepository


func before_each() -> void:
	_fake_ws = FakeWebSocketClient.new()
	_repo = RemoteRoomRepository.new(null, _fake_ws)


func after_each() -> void:
	if _fake_ws != null:
		_fake_ws.free()
		_fake_ws = null


func test_create_builds_real_envelope() -> void:
	_repo.create_room("Minha Sala", true, false)

	assert_eq(_repo._pending_payload, {
		"type": "CREATE_GAME",
		"name": "Minha Sala",
		"settings": {"allowSpectators": true, "privateGame": false},
	})


func test_create_sends_booleans_not_strings() -> void:
	_repo.create_room("Sala", false, true)
	var settings: Dictionary = _repo._pending_payload["settings"]

	assert_true(settings["allowSpectators"] is bool)
	assert_true(settings["privateGame"] is bool)
	assert_false(settings["allowSpectators"])
	assert_true(settings["privateGame"])


func test_create_ignores_duplicate_while_pending() -> void:
	_repo.create_room("Uma", true, false)
	_repo.create_room("Outra", false, true)

	assert_eq((_repo._pending_payload as Dictionary)["name"], "Uma")


func test_game_created_emits_room_and_releases() -> void:
	watch_signals(_repo)
	_repo.create_room("Minha Sala", true, false)
	_fake_ws.emit_message_dict({
		"event": "GAME_CREATED",
		"data": {
			"gameId": "g-1",
			"gameName": "Minha Sala",
			"type": "CUSTOM",
			"status": "WAITING",
			"participants": [],
		},
	})

	assert_signal_emitted(_repo, "room_created")
	assert_signal_not_emitted(_repo, "create_failed")
	assert_true((_repo._pending_payload as Dictionary).is_empty())


func test_error_event_emits_create_failed() -> void:
	watch_signals(_repo)
	_repo.create_room("Minha Sala", true, false)
	_fake_ws.emit_message_dict({"event": "ERROR", "message": "the room name is invalid"})

	assert_signal_emitted(_repo, "create_failed")
	assert_signal_not_emitted(_repo, "room_created")


func test_disconnect_during_create_fails() -> void:
	watch_signals(_repo)
	_repo.create_room("Minha Sala", true, false)
	_fake_ws.disconnected.emit()

	assert_signal_emitted(_repo, "create_failed")


func test_unrelated_events_are_ignored() -> void:
	watch_signals(_repo)
	_repo.create_room("Minha Sala", true, false)
	_fake_ws.emit_message_dict({"event": "PLAYER_ACTION_RESULT", "data": {}})

	assert_signal_not_emitted(_repo, "room_created")
	assert_signal_not_emitted(_repo, "create_failed")
	assert_false((_repo._pending_payload as Dictionary).is_empty())


func test_join_builds_real_envelope() -> void:
	_repo.join_room("g-42")

	assert_eq(_repo._join_payload, {"type": "JOIN_GAME", "gameId": "g-42"})


func test_join_ignores_duplicate_while_pending() -> void:
	_repo.join_room("g-1")
	_repo.join_room("g-2")

	assert_eq((_repo._join_payload as Dictionary)["gameId"], "g-1")


func test_participant_join_emits_room_and_releases() -> void:
	watch_signals(_repo)
	_repo.join_room("g-42")
	_fake_ws.emit_message_dict({
		"event": "PARTICIPANT_JOIN",
		"data": {
			"gameId": "g-42",
			"gameName": "Copa",
			"type": "CUSTOM",
			"status": "WAITING",
			"participants": [],
		},
	})

	assert_signal_emitted(_repo, "room_joined")
	assert_signal_not_emitted(_repo, "join_failed")
	assert_true((_repo._join_payload as Dictionary).is_empty())


func test_error_event_emits_join_failed() -> void:
	watch_signals(_repo)
	_repo.join_room("g-42")
	_fake_ws.emit_message_dict({"event": "ERROR", "message": "the game is full"})

	assert_signal_emitted(_repo, "join_failed")
	assert_signal_not_emitted(_repo, "room_joined")


func test_disconnect_during_join_fails() -> void:
	watch_signals(_repo)
	_repo.join_room("g-42")
	_fake_ws.disconnected.emit()

	assert_signal_emitted(_repo, "join_failed")


func test_join_ignores_create_success_event() -> void:
	watch_signals(_repo)
	_repo.join_room("g-42")
	_fake_ws.emit_message_dict({
		"event": "GAME_CREATED",
		"data": {"gameId": "g-9", "gameName": "Outra", "status": "WAITING", "participants": []},
	})

	assert_signal_not_emitted(_repo, "room_joined")
	assert_signal_not_emitted(_repo, "join_failed")
	assert_false((_repo._join_payload as Dictionary).is_empty())
