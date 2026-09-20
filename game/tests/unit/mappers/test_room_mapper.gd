extends GutTest


func _room_dict(room_id: String, room_name: String, status: String) -> Dictionary:
	return {
		"gameId": room_id,
		"gameName": room_name,
		"type": "CUSTOM",
		"status": status,
		"participants": [
			{"id": "u1", "nickname": "Ana", "role": "PLAYER", "isConnected": true},
			{"id": "u2", "nickname": "Beto", "role": "PLAYER", "isConnected": true},
		],
		"positions": {},
		"matches": [],
	}


func test_from_dictionary_parses_game_response() -> void:
	var room := RoomMapper.from_dictionary(_room_dict("g-1", "Sala da Ana", "WAITING"))

	assert_not_null(room)
	assert_eq(room.game_id, "g-1")
	assert_eq(room.game_name, "Sala da Ana")
	assert_eq(room.status, "WAITING")
	assert_eq(room.players_count(), 2)
	assert_eq(room.host_name(), "Ana")
	assert_eq(room.display_name(), "Sala da Ana")
	assert_true(room.is_joinable())
	assert_eq(room.status_label(), "Aguardando jogadores")


func test_from_dictionary_empty_returns_null() -> void:
	assert_null(RoomMapper.from_dictionary({}))


func test_from_dictionary_without_name_uses_short_id() -> void:
	var room := RoomMapper.from_dictionary(_room_dict("abcdef123456", "", "RUNNING"))

	assert_eq(room.display_name(), "Sala abcdef12")
	assert_false(room.is_joinable())
	assert_eq(room.status_label(), "Em andamento")


func test_status_labels_cover_all_states() -> void:
	var waiting := RoomMapper.from_dictionary(_room_dict("a", "A", "WAITING"))
	var running := RoomMapper.from_dictionary(_room_dict("b", "B", "RUNNING"))
	var closed := RoomMapper.from_dictionary(_room_dict("c", "C", "CLOSED"))
	var canceled := RoomMapper.from_dictionary(_room_dict("d", "D", "CANCELED"))

	assert_eq(waiting.status_label(), "Aguardando jogadores")
	assert_eq(running.status_label(), "Em andamento")
	assert_eq(closed.status_label(), "Fechada")
	assert_eq(canceled.status_label(), "Cancelada")


func test_list_from_array_skips_invalid_entries() -> void:
	var rooms := RoomMapper.list_from_array([
		_room_dict("g-1", "Uma", "WAITING"),
		"invalido",
		_room_dict("g-2", "Duas", "RUNNING"),
	])

	assert_eq(rooms.size(), 2)
	assert_eq((rooms[0] as Room).game_id, "g-1")
	assert_eq((rooms[1] as Room).game_id, "g-2")


func test_page_from_body_parses_content_and_pagination() -> void:
	var body := {
		"success": true,
		"data": {
			"content": [
				_room_dict("g-1", "Uma", "WAITING"),
				_room_dict("g-2", "Duas", "RUNNING"),
			],
			"page": 0,
			"size": 6,
			"totalElements": 2,
			"totalPages": 1,
			"first": true,
			"last": true,
		}
	}

	var result := RoomMapper.page_from_body(body)

	assert_eq((result["rooms"] as Array).size(), 2)
	assert_eq(result["page"], 0)
	assert_eq(result["total_pages"], 1)
	assert_eq(result["total_elements"], 2)


func test_page_from_body_without_data_returns_empty() -> void:
	assert_true(RoomMapper.page_from_body({}).is_empty())
	assert_true(RoomMapper.page_from_body({"data": {}}).is_empty())


func test_code_from_body_parses_game_id() -> void:
	var result := RoomMapper.code_from_body({"success": true, "data": {"gameId": "g-99"}})

	assert_eq(result["game_id"], "g-99")


func test_code_from_body_without_game_id_returns_empty() -> void:
	assert_true(RoomMapper.code_from_body({}).is_empty())
	assert_true(RoomMapper.code_from_body({"data": {}}).is_empty())
	assert_true(RoomMapper.code_from_body({"data": {"gameId": ""}}).is_empty())
